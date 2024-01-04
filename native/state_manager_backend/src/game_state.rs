use rustler::NifMap;
use crate::player::Player;
use std::collections::HashMap;

#[derive(NifMap)]
pub struct GameState {
    pub(crate) players: HashMap<u64, Player>,
}

impl GameState {
    pub fn new() -> GameState {
        GameState{
            players: HashMap::new(),
        }
    }
}
