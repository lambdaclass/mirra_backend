use std::collections::HashMap;
use std::f32::consts::PI;
use std::ops::Div;
use std::ops::Neg;

use rustler::NifMap;
use rustler::NifTaggedEnum;

use crate::character::CharacterConfig;
use crate::config::Config;
use crate::effect::Effect;
use crate::map::Position;

#[derive(NifMap)]
pub struct Player {
    id: u64,
    character: CharacterConfig,
    status: PlayerStatus,
    kill_count: u64,
    death_count: u64,
    position: Position,
    direction: u64,
    actions: Vec<PlayerAction>,
    health: u64,
    cooldowns: HashMap<String, u64>,
    effects: Vec<Effect>,
    size: u64,
    damage: u64,
    speed: u64,
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
        if self.speed <= 0 {
            return;
        }

        let angle_rad = angle_degrees * (PI / 180.0);
        let new_x = (self.position.x as f32) + (self.speed as f32) * angle_rad.cos();
        let new_y = (self.position.y as f32) + (self.speed as f32) * angle_rad.sin();

        let max_x_bound = config.game.width.div(2) as f32;
        let min_x_bound = max_x_bound.neg();
        let x = new_x.min(max_x_bound).max(min_x_bound);

        let max_y_bound = config.game.height.div(2) as f32;
        let min_y_bound = max_y_bound.neg();
        let y = new_y.min(max_y_bound).max(min_y_bound);

        self.position = Position {
            x: x as i64,
            y: y as i64,
        }
    }
}
