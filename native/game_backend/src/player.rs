use std::collections::HashMap;

use itertools::Itertools;
use rustler::NifMap;
use rustler::NifTaggedEnum;

use crate::character::CharacterConfig;
use crate::config::Config;
use crate::effect::AttributeModifier;
use crate::effect::Effect;
use crate::effect::TimeType;
use crate::game::DamageTracker;
use crate::game::EntityOwner;
use crate::loot::Loot;
use crate::map;
use crate::map::Position;

#[derive(NifMap)]
pub struct Player {
    pub id: u64,
    pub character: CharacterConfig,
    pub status: PlayerStatus,
    pub kill_count: u64,
    pub death_count: u64,
    pub position: Position,
    pub direction: f32,
    pub action: Vec<ActionTracker>,
    pub health: u64,
    pub cooldowns: HashMap<String, u64>,
    pub effects: Vec<(Effect, EntityOwner)>,
    pub size: u64,
    pub speed: u64,
    pub skills_keys_to_execute: Vec<String>,
    pub inventory: Vec<Option<Loot>>,
    next_actions: Vec<ActionTracker>,
}

#[derive(NifTaggedEnum, Clone, PartialEq, Eq)]
pub enum PlayerStatus {
    Alive,
    Death,
}

#[derive(NifTaggedEnum, Clone, PartialEq, Eq, Debug)]
pub enum Action {
    Nothing,
    Moving,
    UsingSkill(String),
}

#[derive(NifMap, Clone, Debug)]
pub struct ActionTracker {
    pub action: Action,
    pub duration: u64,
}

impl Player {
    pub fn new(id: u64, character_config: CharacterConfig, initial_position: Position) -> Self {
        Self {
            id,
            status: PlayerStatus::Alive,
            kill_count: 0,
            death_count: 0,
            position: initial_position,
            direction: 0.0,
            action: Vec::new(),
            cooldowns: HashMap::new(),
            effects: Vec::new(),
            health: character_config.base_health,
            speed: character_config.base_speed,
            size: character_config.base_size,
            inventory: vec![None; character_config.max_inventory_size as usize],
            character: character_config,
            next_actions: Vec::new(),
            skills_keys_to_execute: Vec::new(),
        }
    }

    pub fn add_kill(&mut self) {
        self.kill_count += 1;
    }

    pub fn move_position(&mut self, angle_degrees: f32, config: &Config) {
        // A speed of 0 (or less) means the player can't move (e.g. paralyzed, frozen, etc)
        if self.speed == 0 {
            return;
        }

        self.add_action(Action::Moving, 0);
        self.direction = angle_degrees;
        self.position = map::next_position(
            &self.position,
            angle_degrees,
            self.speed as f32,
            config.game.width as f32,
        );
    }

    pub fn add_action(&mut self, action: Action, duration_ms: u64) {
        self.next_actions.push(ActionTracker {
            action,
            duration: duration_ms,
        });
    }

    pub fn update_actions(&mut self, elapsed_time_ms: u64) {
        if let Some(action_tracker) = self.next_actions.first_mut() {
            action_tracker.duration = action_tracker.duration.saturating_sub(elapsed_time_ms);

            if action_tracker.duration == 0 {
                self.next_actions.remove(0);
            }
        }
        self.action = self.next_actions.clone();
    }

    pub fn add_cooldown(&mut self, skill_key: &String, cooldown_ms: u64) {
        self.cooldowns.insert(skill_key.to_string(), cooldown_ms);
    }

    pub fn reduce_cooldowns(&mut self, elapsed_time_ms: u64) {
        self.cooldowns.retain(|_key, remaining| {
            *remaining = remaining.saturating_sub(elapsed_time_ms);
            *remaining > 0
        });
    }

    pub fn apply_effects_if_not_present(
        &mut self,
        outside_radius_effects: &[Effect],
        owner: EntityOwner,
    ) {
        for effect in outside_radius_effects.iter() {
            if self
                .effects
                .iter()
                .any(|(player_effect, _owner)| player_effect.name == effect.name)
            {
                continue;
            }

            self.apply_effect(effect, owner)
        }
    }

    pub fn apply_effects(&mut self, effects: &[Effect], owner: EntityOwner) {
        effects
            .iter()
            .for_each(|effect| self.apply_effect(effect, owner));
    }

    pub fn apply_effect(&mut self, effect: &Effect, owner: EntityOwner) {
        // Store the effect in the player if it is not an instant effect
        if effect.effect_time_type != TimeType::Instant {
            self.effects.push((effect.clone(), owner));
        }

        // Apply the effect
        match effect.effect_time_type {
            TimeType::Periodic {
                instant_applicaiton: false,
                ..
            } => (),
            _ => {
                effect
                    .player_attributes
                    .iter()
                    .fold(self, |player, change| {
                        match change.attribute.as_str() {
                            "speed" => {
                                modify_attribute(&mut player.speed, &change.modifier, &change.value)
                            }
                            "size" => {
                                modify_attribute(&mut player.size, &change.modifier, &change.value)
                            }
                            "health" => {
                                modify_attribute(
                                    &mut player.health,
                                    &change.modifier,
                                    &change.value,
                                );
                                update_status(player);
                            }
                            _ => todo!(),
                        };
                        player
                    });
            }
        };
    }

    pub fn remove_effect(&mut self, effect_key: &str) {
        if let Some(pos) = self
            .effects
            .iter()
            .position(|(effect, _owner)| effect.name == effect_key)
        {
            let (effect, _owner) = self.effects.remove(pos);

            if effect.is_reversable {
                effect.player_attributes.iter().for_each(|change| {
                    match change.attribute.as_str() {
                        "health" => {
                            revert_attribute(&mut self.health, &change.modifier, &change.value)
                        }
                        "size" => revert_attribute(&mut self.size, &change.modifier, &change.value),
                        "speed" => {
                            revert_attribute(&mut self.speed, &change.modifier, &change.value)
                        }
                        _ => todo!(),
                    };
                });
            }
        }
    }

    pub fn decrease_health(&mut self, amount: u64) {
        self.health = self.health.saturating_sub(amount);
        update_status(self);
    }

    pub fn remove_expired_effects(&mut self) {
        let effects_to_remove: Vec<_> = self
            .effects
            .iter()
            .filter(|(effect, _owner)| {
                matches!(
                    effect.effect_time_type,
                    TimeType::Duration { duration_ms: 0 }
                        | TimeType::Periodic {
                            trigger_count: 0,
                            ..
                        }
                )
            })
            .cloned()
            .collect();

        for (effect, _owner) in effects_to_remove.iter() {
            if !effect.is_reversable {
                continue;
            }

            effect.player_attributes.iter().for_each(|change| {
                match change.attribute.as_str() {
                    "health" => revert_attribute(&mut self.health, &change.modifier, &change.value),
                    "size" => revert_attribute(&mut self.size, &change.modifier, &change.value),
                    "speed" => revert_attribute(&mut self.speed, &change.modifier, &change.value),
                    _ => todo!(),
                };
            });
        }

        // Clean effects that have timed out
        self.effects.retain(|(effect, _owner)| {
            !matches!(
                effect.effect_time_type,
                TimeType::Duration { duration_ms: 0 }
                    | TimeType::Periodic {
                        trigger_count: 0,
                        ..
                    }
            )
        });
    }

    pub fn run_effects(&mut self, time_diff: u64) -> Vec<DamageTracker> {
        let mut skills_keys_to_execute: Vec<String> = Vec::new();
        let mut damages: Vec<DamageTracker> = Vec::new();

        for (effect, owner) in self.effects.iter_mut() {
            match &mut effect.effect_time_type {
                TimeType::Duration { duration_ms } => {
                    *duration_ms = (*duration_ms).saturating_sub(time_diff);
                }
                TimeType::Periodic {
                    interval_ms,
                    trigger_count,
                    time_since_last_trigger,
                    ..
                } => {
                    *time_since_last_trigger += time_diff;

                    if *time_since_last_trigger >= *interval_ms {
                        *time_since_last_trigger -= *interval_ms;
                        *trigger_count -= 1;

                        effect
                            .skills_keys_to_execute
                            .iter()
                            .for_each(|skill| skills_keys_to_execute.push(skill.to_string()));

                        effect.player_attributes.iter().for_each(|change| {
                            match change.attribute.as_str() {
                                "health" => {
                                    damages.push(DamageTracker {
                                        damage: change.value.parse::<i64>().unwrap(),
                                        attacker: *owner,
                                        attacked_id: self.id,
                                        on_hit_effects: vec![],
                                    });
                                }

                                _ => todo!(),
                            };
                        });
                    }
                }
                _ => todo!(),
            }
        }
        self.skills_keys_to_execute = skills_keys_to_execute;
        damages
    }

    pub fn put_in_inventory(&mut self, loot: &Loot) -> bool {
        match self
            .inventory
            .iter_mut()
            .find_position(|element| element.is_none())
        {
            Some((slot_at, _)) => {
                self.inventory[slot_at] = Some(loot.clone());
                true
            }
            None => false,
        }
    }

    pub fn inventory_take_at(&mut self, inventory_at: usize) -> Option<Loot> {
        self.inventory[inventory_at].take()
    }

    pub fn can_move(&self) -> bool {
        self.action.first().is_none()
    }

    pub fn can_activate(&self) -> bool {
        self.action.first().is_none()
    }
}

fn update_status(player: &mut Player) {
    if player.health == 0 {
        player.status = PlayerStatus::Death;
    }
}

fn modify_attribute(attribute_value: &mut u64, modifier: &AttributeModifier, value: &str) {
    match modifier {
        AttributeModifier::Additive => {
            *attribute_value =
                (*attribute_value).saturating_add_signed(value.parse::<i64>().unwrap())
        }
        AttributeModifier::Multiplicative => {
            *attribute_value = ((*attribute_value as f64) * value.parse::<f64>().unwrap()) as u64
        }
        AttributeModifier::Override => *attribute_value = value.parse::<u64>().unwrap(),
    }
}

fn revert_attribute(attribute_value: &mut u64, modifier: &AttributeModifier, value: &str) {
    match modifier {
        AttributeModifier::Additive => {
            *attribute_value =
                (*attribute_value).saturating_sub(value.parse::<i64>().unwrap() as u64)
        }
        AttributeModifier::Multiplicative => {
            *attribute_value = ((*attribute_value as f64) / value.parse::<f64>().unwrap()) as u64
        }
        // We are not handling the possibility to revert an Override effect because we are not storing the previous value.
        _ => todo!(),
    }
}
