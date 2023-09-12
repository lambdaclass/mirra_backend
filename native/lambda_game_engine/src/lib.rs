mod character;
mod config;
mod effect;
mod loot;
mod projectile;
mod skill;
mod myra_engine;

use std::collections::HashMap;

use rustler::Binary;

use crate::{config::Config, myra_engine::{game::{GameState, Direction}, utils::RelativePosition}};

#[rustler::nif(schedule = "DirtyCpu")]
fn parse_config(data: String) -> Config {
    config::parse_config(&data)
}

/********************************************************
 * Functions in this space are copied from Myra engine  *
 * after the refactor there should be nothing down here *
 ********************************************************/
#[rustler::nif(schedule = "DirtyCpu")]
fn new_game(
    selected_players: HashMap<u64, String>,
    number_of_players: u64,
    board_width: usize,
    board_height: usize,
    build_walls: bool,
    raw_characters_config: Vec<HashMap<Binary, Binary>>,
    raw_skills_config: Vec<HashMap<Binary, Binary>>,
) -> Result<GameState, String> {
    myra_engine::new_game(selected_players, number_of_players, board_width, board_height, build_walls, raw_characters_config, raw_skills_config)
}

#[rustler::nif(schedule = "DirtyCpu")]
fn move_player(game: GameState, player_id: u64, direction: Direction) -> Result<GameState, String> {
    myra_engine::move_player(game, player_id, direction)
}

#[rustler::nif(schedule = "DirtyCpu")]
fn world_tick(game: GameState, out_of_area_damage: i64) -> GameState {
    myra_engine::world_tick(game, out_of_area_damage)
}

#[rustler::nif(schedule = "DirtyCpu")]
fn skill_1(
    game: GameState,
    attacking_player_id: u64,
    attack_position: RelativePosition,
) -> Result<GameState, String> {
    myra_engine::skill_1(game, attacking_player_id, attack_position)
}

#[rustler::nif(schedule = "DirtyCpu")]
fn skill_2(
    game: GameState,
    attacking_player_id: u64,
    attack_position: RelativePosition,
) -> Result<GameState, String> {
    myra_engine::skill_2(game, attacking_player_id, attack_position)
}

#[rustler::nif(schedule = "DirtyCpu")]
fn skill_3(
    game: GameState,
    attacking_player_id: u64,
    attack_position: RelativePosition,
) -> Result<GameState, String> {
    myra_engine::skill_3(game, attacking_player_id, attack_position)
}

#[rustler::nif(schedule = "DirtyCpu")]
fn skill_4(
    game: GameState,
    attacking_player_id: u64,
    attack_position: RelativePosition,
) -> Result<GameState, String> {
    myra_engine::skill_4(game, attacking_player_id, attack_position)
}

#[rustler::nif(schedule = "DirtyCpu")]
fn disconnect(game: GameState, player_id: u64) -> Result<GameState, String> {
    myra_engine::disconnect(game, player_id)
}

#[rustler::nif(schedule = "DirtyCpu")]
fn move_with_joystick(
    game: GameState,
    player_id: u64,
    x: f32,
    y: f32,
) -> Result<GameState, String> {
    myra_engine::move_with_joystick(game, player_id, x, y)
}

#[rustler::nif(schedule = "DirtyCpu")]
fn basic_attack(
    game: GameState,
    player_id: u64,
    direction: RelativePosition,
) -> Result<GameState, String> {
    myra_engine::basic_attack(game, player_id, direction)
}

#[rustler::nif(schedule = "DirtyCpu")]
fn spawn_player(game: GameState, player_id: u64) -> Result<GameState, String> {
    myra_engine::spawn_player(game, player_id)
}

#[rustler::nif(schedule = "DirtyCpu")]
fn shrink_map(game: GameState, map_shrink_minimum_radius: u64) -> Result<GameState, String> {
    myra_engine::shrink_map(game, map_shrink_minimum_radius)
}

#[rustler::nif(schedule = "DirtyCpu")]
fn spawn_loot(game: GameState) -> Result<GameState, String> {
    myra_engine::spawn_loot(game)
}

rustler::init!("Elixir.LambdaGameEngine", [parse_config, new_game, move_player, world_tick, disconnect, move_with_joystick, spawn_player, basic_attack, skill_1, skill_2, skill_3, skill_4, shrink_map, spawn_loot]);
