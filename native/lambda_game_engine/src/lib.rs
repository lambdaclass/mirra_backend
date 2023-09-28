mod character;
mod config;
mod effect;
mod game;
mod loot;
mod map;
mod myrra_engine;
mod player;
mod projectile;
mod skill;

use std::collections::HashMap;

use rustler::Binary;

use crate::config::Config;
use crate::game::GameState;
use crate::myrra_engine::utils::RelativePosition;
use crate::player::Player;

#[rustler::nif(schedule = "DirtyCpu")]
fn parse_config(data: String) -> Config {
    config::parse_config(&data)
}

#[rustler::nif(schedule = "DirtyCpu")]
fn engine_new_game(config: Config) -> GameState {
    GameState::new(config)
}

#[rustler::nif(schedule = "DirtyCpu")]
fn add_player(game: GameState, character_name: String) -> (GameState, Option<u64>) {
    let mut game = game;
    let player_id = game.next_id();
    match game.config.find_character(character_name) {
        None => (game, None),
        Some(character_config) => {
            let player = Player::new(player_id, character_config);
            game.push_player(player_id, player);
            (game, Some(player_id))
        }
    }
}

#[rustler::nif(schedule = "DirtyCpu")]
fn move_player(game: GameState, player_id: u64, angle: f32) -> GameState {
    let mut game = game;
    match game.players.get_mut(&player_id) {
        None => game,
        Some(player) => {
            player.move_position(angle, &game.config);
            game
        }
    }
}

/********************************************************
 * Functions in this space are copied from Myrra engine *
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
    raw_config: String,
) -> Result<GameState, String> {
    match myrra_engine::new_game(
        selected_players,
        number_of_players,
        board_width,
        board_height,
        build_walls,
        raw_characters_config,
        raw_skills_config,
    ) {
        Ok(myrra_state) => {
            let config = config::parse_config(&raw_config);
            let mut game_state = GameState::new(config);
            game_state.update_myrra_state(myrra_state);
            Ok(game_state)
        }
        Err(error) => Err(error),
    }
}

#[rustler::nif(schedule = "DirtyCpu")]
fn world_tick(game: GameState, out_of_area_damage: i64) -> GameState {
    let mut game = game;
    let myrra_state = myrra_engine::world_tick(game.myrra_state.clone(), out_of_area_damage);
    game.update_myrra_state(myrra_state);
    game
}

#[rustler::nif(schedule = "DirtyCpu")]
fn skill_1(
    game: GameState,
    attacking_player_id: u64,
    attack_position: RelativePosition,
) -> Result<GameState, String> {
    let myrra_state = myrra_engine::skill_1(
        game.myrra_state.clone(),
        attacking_player_id,
        attack_position,
    );
    update_myrra_state_result(game, myrra_state)
}

#[rustler::nif(schedule = "DirtyCpu")]
fn skill_2(
    game: GameState,
    attacking_player_id: u64,
    attack_position: RelativePosition,
) -> Result<GameState, String> {
    let myrra_state = myrra_engine::skill_2(
        game.myrra_state.clone(),
        attacking_player_id,
        attack_position,
    );
    update_myrra_state_result(game, myrra_state)
}

#[rustler::nif(schedule = "DirtyCpu")]
fn skill_3(
    game: GameState,
    attacking_player_id: u64,
    attack_position: RelativePosition,
) -> Result<GameState, String> {
    let myrra_state = myrra_engine::skill_3(
        game.myrra_state.clone(),
        attacking_player_id,
        attack_position,
    );
    update_myrra_state_result(game, myrra_state)
}

#[rustler::nif(schedule = "DirtyCpu")]
fn skill_4(
    game: GameState,
    attacking_player_id: u64,
    attack_position: RelativePosition,
) -> Result<GameState, String> {
    let myrra_state = myrra_engine::skill_4(
        game.myrra_state.clone(),
        attacking_player_id,
        attack_position,
    );
    update_myrra_state_result(game, myrra_state)
}

#[rustler::nif(schedule = "DirtyCpu")]
fn disconnect(game: GameState, player_id: u64) -> Result<GameState, String> {
    let myrra_state = myrra_engine::disconnect(game.myrra_state.clone(), player_id);
    update_myrra_state_result(game, myrra_state)
}

#[rustler::nif(schedule = "DirtyCpu")]
fn move_with_joystick(
    game: GameState,
    player_id: u64,
    x: f32,
    y: f32,
) -> Result<GameState, String> {
    let myrra_state = myrra_engine::move_with_joystick(game.myrra_state.clone(), player_id, x, y);
    update_myrra_state_result(game, myrra_state)
}

#[rustler::nif(schedule = "DirtyCpu")]
fn basic_attack(
    game: GameState,
    player_id: u64,
    direction: RelativePosition,
) -> Result<GameState, String> {
    let myrra_state = myrra_engine::basic_attack(game.myrra_state.clone(), player_id, direction);
    update_myrra_state_result(game, myrra_state)
}

#[rustler::nif(schedule = "DirtyCpu")]
fn spawn_player(game: GameState, player_id: u64) -> Result<GameState, String> {
    let myrra_state = myrra_engine::spawn_player(game.myrra_state.clone(), player_id);
    update_myrra_state_result(game, myrra_state)
}

#[rustler::nif(schedule = "DirtyCpu")]
fn shrink_map(game: GameState, map_shrink_minimum_radius: u64) -> Result<GameState, String> {
    let myrra_state = myrra_engine::shrink_map(game.myrra_state.clone(), map_shrink_minimum_radius);
    update_myrra_state_result(game, myrra_state)
}

#[rustler::nif(schedule = "DirtyCpu")]
fn spawn_loot(game: GameState) -> Result<GameState, String> {
    let myrra_state = myrra_engine::spawn_loot(game.myrra_state.clone());
    update_myrra_state_result(game, myrra_state)
}

fn update_myrra_state_result(
    mut game: GameState,
    myrra_state_result: Result<crate::myrra_engine::game::GameState, String>,
) -> Result<GameState, String> {
    match myrra_state_result {
        Err(error) => Err(error),
        Ok(myrra_state) => {
            game.update_myrra_state(myrra_state);
            Ok(game)
        }
    }
}

rustler::init!(
    "Elixir.LambdaGameEngine",
    [
        parse_config,
        engine_new_game,
        add_player,
        move_player,
        new_game,
        world_tick,
        disconnect,
        move_with_joystick,
        spawn_player,
        basic_attack,
        skill_1,
        skill_2,
        skill_3,
        skill_4,
        shrink_map,
        spawn_loot
    ]
);
