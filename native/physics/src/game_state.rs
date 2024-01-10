use crate::map::Entity;

use rustler::NifMap;
use std::collections::HashMap;

#[derive(NifMap)]
pub struct GameState {
    pub(crate) game_id: String,
    pub(crate) entities: HashMap<u64, Entity>,
    pub(crate) last_id: u64,
}

impl GameState {
    pub fn new(game_id: String) -> GameState {
        GameState {
            game_id,
            entities: HashMap::new(),
            last_id: 0,
        }
    }
}
