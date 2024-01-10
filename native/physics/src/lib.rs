#![allow(non_snake_case)] // rustler macros generate non snake case names and dont use this allow themselves

mod collision_detection;
mod game_state;
mod map;

use std::collections::HashMap;

use crate::game_state::GameState;
use crate::map::{Direction, Entity, Position};

#[rustler::nif()]
fn add(a: i64, b: i64) -> i64 {
    a + b
}

#[rustler::nif()]
fn new_game(game_id: String) -> GameState {
    GameState::new(game_id)
}

#[rustler::nif()]
fn move_player(game_state: GameState, player_id: u64, x: f64, y: f64) -> GameState {
    let mut game_state: GameState = game_state;
    let entity = game_state.entities.get_mut(&player_id).unwrap();
    entity.set_direction(x, y);
    game_state
}

#[rustler::nif()]
fn move_entities(game_state: GameState) -> GameState {
    let mut game_state: GameState = game_state;

    for entity in game_state.entities.values_mut() {
        entity.move_entity();
    }

    game_state
}

#[rustler::nif()]
/// Check players inside the player_id radius
/// Return a list of the players id inside the radius Vec<player_id>
fn check_collisions(entity: Entity, entities: HashMap<u64, Entity>) -> bool {
    let mut entity: Entity = entity;
    let ent = entities.into_values().collect();

    if entity.shape == map::Shape::Circle {
        return !entity.collides_with(ent).is_empty();
    }

    false
}

rustler::init!(
    "Elixir.Physics",
    [
        add,
        move_player,
        new_game,
        check_collisions,
        move_entities
    ]
);
