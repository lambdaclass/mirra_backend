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
    pub direction: u64,
    pub actions: Vec<PlayerAction>,
    pub health: u64,
    pub cooldowns: HashMap<String, u64>,
    pub effects: Vec<Effect>,
    pub size: u64,
    pub damage: u64,
    pub speed: u64,
}

#[derive(NifTaggedEnum, Clone)]
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
            direction: 0,
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

        self.position = map::next_position(&self.position, angle_degrees, self.speed as f32, config.game.width as f32, config.game.height as f32);
    }

    pub fn apply_effect(&mut self, effect: &Effect) {
        // Store the effect in the player if it is not an instant effect
        if effect.effect_time_type != TimeType::Instant {
            self.effects.push(effect.clone());
        }

        // Apply the effect
        match effect.effect_time_type {
            TimeType::Periodic {
                instant_applicaiton: true,
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
}

fn modify_attribute(attribute_value: &mut u64, modifier: &AttributeModifier, value: &str) {
    match modifier {
        AttributeModifier::Additive => *attribute_value += value.parse::<u64>().unwrap(),
        AttributeModifier::Multiplicative => {
            *attribute_value = ((*attribute_value as f64) * value.parse::<f64>().unwrap()) as u64
        }
        AttributeModifier::Override => *attribute_value = value.parse::<u64>().unwrap(),
    }
}
