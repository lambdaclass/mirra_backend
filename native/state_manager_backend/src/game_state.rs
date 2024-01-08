use crate::map::Entity;
use rustler::NifMap;
use std::collections::HashMap;

#[derive(NifMap)]
pub struct GameState {
    pub(crate) entities: HashMap<u64, Entity>,
}

impl GameState {
    pub fn new() -> GameState {
        GameState {
            entities: HashMap::new(),
        }
    }
}
