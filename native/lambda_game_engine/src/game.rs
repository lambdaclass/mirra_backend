use std::collections::HashMap;

use rustler::NifMap;
use rustler::NifTaggedEnum;
use serde::Deserialize;

use crate::config::Config;
use crate::effect::Effect;
use crate::loot::Loot;
use crate::map;
use crate::player::Player;

#[derive(Deserialize)]
pub struct GameConfigFile {
    width: u64,
    height: u64,
    loot_interval_ms: u64,
    map_modification: MapModificationConfigFile,
}

#[derive(Deserialize)]
pub struct MapModificationConfigFile {
    starting_radius: u64,
    minimum_radius: u64,
    max_radius: u64,
    outside_radius_effects: Vec<String>,
    inside_radius_effects: Vec<String>,
    modification: MapModificationModifier,
}

#[derive(NifMap)]
pub struct GameConfig {
    pub width: u64,
    pub height: u64,
    pub loot_interval_ms: u64,
    pub map_modification: MapModificationConfig,
}

#[derive(NifMap)]
pub struct MapModificationConfig {
    starting_radius: u64,
    minimum_radius: u64,
    max_radius: u64,
    outside_radius_effects: Vec<Effect>,
    inside_radius_effects: Vec<Effect>,
    modification: MapModificationModifier,
}

#[derive(Deserialize, NifTaggedEnum)]
#[serde(tag = "modifier", content = "value")]
pub enum MapModificationModifier {
    Additive(u64),
    Multiplicative(f64),
}

#[derive(NifMap)]
pub struct GameState {
    pub config: Config,
    pub players: HashMap<u64, Player>,
    pub loots: Vec<Loot>,
    pub myrra_state: crate::myrra_engine::game::GameState,
    pub next_id: u64,
}

impl GameConfig {
    pub(crate) fn from_config_file(
        game_config: GameConfigFile,
        effects: &Vec<Effect>,
    ) -> GameConfig {
        let outside_effects = find_effects(
            &game_config.map_modification.outside_radius_effects,
            effects,
        );
        let inside_effects =
            find_effects(&game_config.map_modification.inside_radius_effects, effects);

        GameConfig {
            width: game_config.width,
            height: game_config.height,
            loot_interval_ms: game_config.loot_interval_ms,
            map_modification: MapModificationConfig {
                starting_radius: game_config.map_modification.starting_radius,
                minimum_radius: game_config.map_modification.minimum_radius,
                max_radius: game_config.map_modification.max_radius,
                outside_radius_effects: outside_effects,
                inside_radius_effects: inside_effects,
                modification: game_config.map_modification.modification,
            },
        }
    }
}

impl GameState {
    pub fn new(config: Config) -> Self {
        Self {
            config,
            players: HashMap::new(),
            loots: Vec::new(),
            next_id: 1,
            myrra_state: crate::myrra_engine::game::GameState::placeholder_new(),
        }
    }

    pub fn next_id(&mut self) -> u64 {
        let id = self.next_id;
        self.next_id += 1;
        id
    }

    pub fn push_player(&mut self, player_id: u64, player: Player) {
        self.players.insert(player_id, player);
    }

    pub fn push_loot(&mut self, loot: Loot) {
        self.loots.push(loot);
    }

    pub fn update_myrra_state(&mut self, myrra_state: crate::myrra_engine::game::GameState) {
        self.myrra_state = myrra_state;
    }

    pub fn move_player(&mut self, player_id: u64, angle: f32) {
        let players = &mut self.players;
        let loots = &mut self.loots;
        if let Some(player) = players.get_mut(&player_id) {
            player.move_position(angle, &self.config);
            collect_nearby_loot(loots, player);
        }
    }
}

fn find_effects(config_effects_names: &Vec<String>, effects: &Vec<Effect>) -> Vec<Effect> {
    config_effects_names
        .into_iter()
        .map(|config_effect_name| {
            effects
                .into_iter()
                .find(|effect| config_effect_name.to_string() == effect.name)
                .expect(
                    format!(
                        "Game map_modification effect `{}` does not exist in effects config",
                        config_effect_name
                    )
                    .as_str(),
                )
                .clone()
        })
        .collect()
}

fn collect_nearby_loot(loots: &mut Vec<Loot>, player: &mut Player) {
    loots.retain(|loot| {
        if map::hit_boxes_collide(&loot.position, &player.position, loot.size, player.size) {
            loot.effects.iter().for_each(|effect| player.apply_effect(effect));
            false
        } else {
            true
        }
    });
}
