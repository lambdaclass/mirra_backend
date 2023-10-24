use std::collections::HashMap;

use rustler::NifMap;
use rustler::NifTaggedEnum;

use crate::character::CharacterConfig;
use crate::config::Config;
use crate::effect::AttributeModifier;
use crate::effect::Effect;
use crate::effect::TimeType;
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
    pub actions: Vec<PlayerAction>,
    pub health: u64,
    pub cooldowns: HashMap<String, u64>,
    pub effects: Vec<Effect>,
    pub size: u64,
    pub damage: u64,
    pub speed: u64,
}

#[derive(NifTaggedEnum, Clone, PartialEq)]
pub enum PlayerStatus {
    Alive,
    Death,
}

#[derive(NifTaggedEnum, Clone)]
pub enum PlayerAction {
    Nothing,
    Attacking,
    Attackingaoe,
    Moving,
    StartingSkill(String),
    ExecutingSkill(String),
}

impl Player {
    pub fn new(id: u64, character_config: CharacterConfig) -> Self {
        Self {
            id,
            status: PlayerStatus::Alive,
            kill_count: 0,
            death_count: 0,
            position: Position { x: 0, y: 0 }, // TODO: random_position
            direction: 0.0,
            actions: Vec::new(),
            cooldowns: HashMap::new(),
            effects: Vec::new(),
            health: 100, //TODO: character_config.base_max_health,
            damage: 15,  //TODO: character_config.base_damage,
            speed: character_config.base_speed,
            size: character_config.base_size,
            character: character_config,
        }
    }

    pub fn move_position(&mut self, angle_degrees: f32, config: &Config) {
        // A speed of 0 (or less) means the player can't move (e.g. paralyzed, frozen, etc)
        if self.speed == 0 {
            return;
        }

        self.direction = angle_degrees;
        self.position = map::next_position(
            &self.position,
            angle_degrees,
            self.speed as f32,
            config.game.width as f32,
            config.game.height as f32,
        );
    }

    pub fn apply_effects(&mut self, effects: &[Effect]) {
        effects.iter().for_each(|effect| self.apply_effect(effect))
    }

    pub fn apply_effect(&mut self, effect: &Effect) {
        // Store the effect in the player if it is not an instant effect
        if effect.effect_time_type != TimeType::Instant {
            self.effects.push(effect.clone());
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
                            "damage" => modify_attribute(
                                &mut player.damage,
                                &change.modifier,
                                &change.value,
                            ),
                            "health" => modify_attribute(
                                &mut player.health,
                                &change.modifier,
                                &change.value,
                            ),
                            _ => todo!(),
                        };
                        player
                    });
            }
        };
    }

    pub fn decrease_health(&mut self, amount: u64) {
        self.health = self.health.saturating_sub(amount);

        if self.health == 0 {
            self.status = PlayerStatus::Death;
        }
    }

    pub fn run_effects(&mut self, time_diff: u64) {
        // Clean effects that have timed out
        self.effects.retain(|effect| {
            !matches!(
                effect.effect_time_type,
                TimeType::Duration { duration_ms: 0 }
                    | TimeType::Periodic {
                        trigger_count: 0,
                        ..
                    }
            )
        });

        for effect in self.effects.iter_mut() {
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

                        effect.player_attributes.iter().for_each(|change| {
                            match change.attribute.as_str() {
                                "health" => modify_attribute(
                                    &mut self.health,
                                    &change.modifier,
                                    &change.value,
                                ),
                                _ => todo!(),
                            };
                        });
                    }
                }
                _ => todo!(),
            }
        }
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
