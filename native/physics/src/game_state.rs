use crate::map::Entity;

use rustler::NifMap;
use std::collections::HashMap;

#[derive(NifMap)]
pub struct GameState {
    pub(crate) game_id: String,
    pub(crate) entities: HashMap<u64, Entity>,
    pub(crate) last_id: u64,
    pub(crate) map: Entity,
}

impl GameState {
    pub fn new(game_id: String, map: Entity) -> GameState {
        GameState {
            game_id,
            entities: HashMap::new(),
            last_id: 0,
            map,
        }
    }

    pub fn next_id(&mut self) -> u64 {
        self.last_id += 1;
        self.last_id
    }
}
