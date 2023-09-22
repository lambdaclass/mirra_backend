use rustler::{NifMap, NifTaggedEnum};
use serde::Deserialize;

use crate::effect::Effect;

#[derive(Deserialize)]
pub struct GameConfigFile {
    width: u64,
    height: u64,
    loot_interval_ms: u64,
    map_modification: MapModificationConfigFile
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
    width: u64,
    height: u64,
    loot_interval_ms: u64,
    map_modification: MapModificationConfig
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

impl GameConfig {
  pub(crate) fn from_config_file(
      game_config: GameConfigFile,
      effects: &Vec<Effect>,
  ) -> GameConfig {
    let outside_effects = find_effects(&game_config.map_modification.outside_radius_effects, effects);
    let inside_effects = find_effects(&game_config.map_modification.inside_radius_effects, effects);

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
      }
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
        .expect(format!("Game map_modification effect `{}` does not exist in effects config", config_effect_name).as_str())
        .clone()
      })
      .collect()
}
