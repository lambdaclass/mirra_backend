use rustler::NifMap;
use crate::player::Player;
use std::collections::HashMap;
use crate::map::Polygon;

#[derive(NifMap)]
pub struct GameState {
    pub(crate) players: HashMap<u64, Player>,
    pub(crate) polygons: HashMap<u64, Polygon>,
}

impl GameState {
    pub fn new() -> GameState {
        GameState{
            players: HashMap::new(),
            polygons: HashMap::new(),
        }
    }
}
