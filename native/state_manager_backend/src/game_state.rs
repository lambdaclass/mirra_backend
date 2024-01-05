use crate::{calculate_distance, player::Player};
use rustler::NifMap;
use std::collections::HashMap;

#[derive(NifMap)]
pub struct GameState {
    pub(crate) players: HashMap<u64, Player>,
}

impl GameState {
    pub fn new() -> GameState {
        GameState {
            players: HashMap::new(),
        }
    }

    /// Move the player in the directions x and y
    /// Checking collisions with the other Players in the game
    pub fn move_player(&mut self, player_id: u64, direc_x: f64, direc_y: f64) {
        if !is_valid_move(self, &player_id, direc_x, direc_y) {
            return;
        }
        let player = self.players.get_mut(&player_id).unwrap();
        player.position.x += direc_x * player.speed;
        player.position.y += direc_y * player.speed;
    }
}

/// Check collisions with other Players in the game
pub fn is_valid_move(game_state: &GameState, player_id: &u64, direc_x: f64, direc_y: f64) -> bool {
    let mut player = game_state.players.get(player_id).unwrap().clone();
    player.position.x += direc_x * player.speed;
    player.position.y += direc_y * player.speed;

    let new_position = player.position;

    for (id, other_player) in &game_state.players {
        if id == &player.id {
            continue;
        }

        let distance = calculate_distance(&new_position, &other_player.position);
        if distance < player.size / 2.0 + other_player.size / 2.0 {
            return false;
        }
    }
    true
}
