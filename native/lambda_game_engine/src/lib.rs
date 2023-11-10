mod character;
mod config;
mod effect;
mod game;
mod loot;
mod map;
mod player;
mod projectile;
mod skill;

use std::collections::HashMap;
use crate::config::Config;
use crate::game::{EntityOwner, GameState};
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
    let mut game: GameState = game;
    game.move_player(player_id, angle);
    game
}

// TODO: Is this method necesary?
#[rustler::nif(schedule = "DirtyCpu")]
fn apply_effect(game: GameState, player_id: u64, effect_name: String) -> GameState {
    let mut game = game;
    match game.players.get_mut(&player_id) {
        None => game,
        Some(player) => {
            let effect = game.config.find_effect(effect_name).unwrap();
            player.apply_effect(effect, EntityOwner::Zone);
            game
        }
    }
}

#[rustler::nif(schedule = "DirtyCpu")]
fn spawn_random_loot(game: GameState) -> (GameState, Option<u64>) {
    let mut game = game;
    let loot_id = game.next_id();
    match loot::spawn_random_loot(&game.config, loot_id) {
        None => (game, None),
        Some(loot) => {
            game.push_loot(loot);
            (game, Some(loot_id))
        }
    }
}

#[rustler::nif(schedule = "DirtyCpu")]
fn activate_skill(
    game: GameState,
    player_id: u64,
    skill_key: String,
    skill_params: HashMap<String, String>,
) -> GameState {
    let mut game = game;
    game.activate_skill(player_id, skill_key, skill_params);
    game
}

#[rustler::nif(schedule = "DirtyCpu")]
fn game_tick(game: GameState, time_diff_ms: u64) -> GameState {
    let mut game = game;
    game.tick(time_diff_ms);
    game
}

rustler::init!(
    "Elixir.LambdaGameEngine",
    [
        parse_config,
        engine_new_game,
        add_player,
        move_player,
        apply_effect,
        spawn_random_loot,
        activate_skill,
        game_tick,
    ]
);
