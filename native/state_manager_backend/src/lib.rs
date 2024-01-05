#![allow(non_snake_case)] // rustler macros generate non snake case names and dont use this allow themselves

mod player;
mod game_state;
mod map;

use crate::game_state::GameState;
use crate::player::{Player, Position};
use crate::map::Polygon;

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
fn move_player(game_state: GameState, player_id: u64, x: f64, y: f64) -> GameState {
    let mut game_state: GameState = game_state;
    let player = game_state.players.get_mut(&player_id).unwrap();
    player.move_player(x, y);
    game_state
}

#[rustler::nif()]
/// Check players inside the player_id radius
/// Return a list of the players id inside the radius Vec<player_id>
fn check_collisions(game_state: GameState, player_id: u64, radius: f64) -> Vec<u64> {
    let game_state: GameState = game_state;
    let player = game_state.players.get(&player_id).unwrap();
    let mut result = Vec::new();
    for (id, other_player) in &game_state.players {
        if id == &player.id {
            continue;
        }
        let d = calculate_distance(&player.position, &other_player.position);
        if d <= radius {
            result.push(*id)
        }
    }
    result
}

/// Calculate distance between two positions
fn calculate_distance(a: &Position, b: &Position) -> f64 {
    let x = a.x - b.x;
    let y = a.y - b.y;
    (x.powi(2) + y.powi(2)).sqrt()
}

#[rustler::nif()]
fn add_polygon(game_state: GameState) -> GameState {
    let mut game_state: GameState = game_state;
    
    let polygon = Polygon::new(1, vec![
        Position { x: 30.0, y: 0.0 }, 
        Position { x: 30.0, y: 50.0 }, 
        Position { x: 10.0, y: 50.0 }, 
        Position { x: 0.0, y: 0.0 }]);
    game_state.polygons.insert(polygon.id, polygon);

    let polygon = Polygon::new(2, vec![
        Position { x: 200.0, y: 200.0 },
        Position { x: 400.0, y: 200.0 },
        Position { x: 450.0, y: 300.0 },
        Position { x: 300.0, y: 400.0 },
        Position { x: 100.0, y: 300.0 },
    ]);
    game_state.polygons.insert(polygon.id, polygon);
    game_state
}

#[rustler::nif()]
fn exist_collision(game_state: GameState, position: Position) -> bool {
    let mut game_state: GameState = game_state;
    let mut collision = false;
    for (_, polygon) in game_state.polygons.iter_mut() {
        if polygon.exist_collision(&position) {
            collision = true;
            break;
        }
    }
    collision
}

rustler::init!("Elixir.StateManagerBackend", [
    add,
    move_player,
    new_game,
    add_player,
    check_collisions,
    add_polygon,
    exist_collision
]);
