#![allow(non_snake_case)] // rustler macros generate non snake case names and dont use this allow themselves

mod game_state;
mod player;

use crate::game_state::GameState;
use crate::player::{Player, Position};

#[rustler::nif()]
fn add(a: i64, b: i64) -> i64 {
    a + b
}

#[rustler::nif()]
fn new_game() -> GameState {
    GameState::new()
}

#[rustler::nif()]
fn add_player(game_state: GameState, player_id: u64) -> GameState {
    let mut game_state: GameState = game_state;
    // Check here if the player doesn't exist.
    // If it does, it resets it to [0,0] position.
    let player = Player::new(player_id, Position { x: 0.0, y: 0.0 }, 1.0, 500, 1.0);
    game_state.players.insert(player.id, player);
    game_state
}

#[rustler::nif()]
fn move_player(game_state: GameState, player_id: u64, direc_x: f64, direc_y: f64) -> GameState {
    let mut game_state: GameState = game_state;
    game_state.move_player(player_id, direc_x, direc_y);
    game_state
}

/// Calculate distance between two positions
fn calculate_distance(a: &Position, b: &Position) -> f64 {
    let x = a.x - b.x;
    let y = a.y - b.y;
    (x.powi(2) + y.powi(2)).sqrt()
}

rustler::init!(
    "Elixir.StateManagerBackend",
    [add, move_player, new_game, add_player,]
);
