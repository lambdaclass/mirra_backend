use rustler::NifMap;
use crate::player::Player;
use std::collections::HashMap;

#[derive(NifMap)]
pub struct GameState {
    pub(crate) game_id: String,
    pub(crate) players: HashMap<u64, Player>,
}

impl GameState {
    pub fn new(game_id: String) -> GameState {
        GameState{
            game_id: game_id,
            players: HashMap::new(),
        }
    }
}
