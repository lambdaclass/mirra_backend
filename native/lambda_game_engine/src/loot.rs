use rustler::NifMap;
use serde::Deserialize;

use crate::effect::Effect;
use crate::map::Position;

#[derive(Deserialize, NifMap)]
pub struct LootFileConfig {
    name: String,
    size: u64,
    effects: Vec<String>,
}

#[derive(NifMap)]
pub struct LootConfig {
    name: String,
    size: u64,
    effects: Vec<Effect>,
}

#[derive(NifMap)]
pub struct Loot {
    name: String,
    size: u64,
    effects: Vec<Effect>,
    id: u64,
    position: Position,
}

impl LootConfig {
    pub(crate) fn from_config_file(
        loots: Vec<LootFileConfig>,
        effects: &Vec<Effect>,
    ) -> Vec<LootConfig> {
        loots
            .into_iter()
            .map(|config| {
                let effects = effects
                    .into_iter()
                    .filter(|effect| config.effects.contains(&effect.name))
                    .cloned()
                    .collect();
                LootConfig {
                    name: config.name,
                    size: config.size,
                    effects,
                }
            })
            .collect()
    }
}
