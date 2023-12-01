mod character;
mod config;
mod effect;
mod game;
mod loot;
mod map;
mod player;
mod projectile;
mod skill;

use crate::config::Config;
use crate::game::{EntityOwner, GameError, GameState};
use crate::map::Position;
use crate::player::Player;
use rand::Rng;
use std::collections::HashMap;

#[rustler::nif()]
fn parse_config(data: String) -> Config {
    config::parse_config(&data)
}

#[rustler::nif()]
fn new_game(config: Config) -> GameState {
    GameState::new(config)
}

#[rustler::nif()]
fn add_player(
    game: GameState,
    character_name: String,
) -> Result<(GameState, Option<u64>), GameError> {
    let mut game = game;
    let player_id = game.next_id();
    match game.config.find_character(character_name) {
        None => Err(GameError::CharacterNotFound),
        Some(character_config) => {
            let rng = &mut rand::thread_rng();
            let initial_position = if game.config.game.initial_positions.is_empty() {
                Position { x: 0, y: 0 }
            } else {
                game.config
                    .game
                    .initial_positions
                    .swap_remove(rng.gen_range(0..game.config.game.initial_positions.len()))
            };

            let player = Player::new(player_id, character_config, initial_position);
            game.push_player(player_id, player);
            Ok((game, Some(player_id)))
        }
    }
}

#[rustler::nif()]
fn move_player(game: GameState, player_id: u64, angle: f32) -> GameState {
    let mut game: GameState = game;
    game.move_player(player_id, angle);
    game
}

// TODO: Is this method necesary?
#[rustler::nif()]
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

#[rustler::nif()]
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

#[rustler::nif()]
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

#[rustler::nif()]
fn activate_inventory(game: GameState, player_id: u64, inventory_at: u64) -> GameState {
    let mut game = game;
    game.activate_inventory(player_id, inventory_at as usize);
    game
}

#[rustler::nif()]
fn game_tick(game: GameState, time_diff_ms: u64) -> GameState {
    let mut game = game;
    game.tick(time_diff_ms);
    game
}

rustler::init!(
    "Elixir.GameBackend",
    [
        parse_config,
        new_game,
        add_player,
        move_player,
        apply_effect,
        spawn_random_loot,
        activate_skill,
        activate_inventory,
        game_tick,
    ]
);
