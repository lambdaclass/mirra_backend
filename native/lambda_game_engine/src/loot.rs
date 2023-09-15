use rustler::NifMap;
use serde::Deserialize;

use crate::effect::Effect;

#[derive(Deserialize, NifMap)]
pub struct LootFileConfig {
    name: String,
    effects: Vec<String>,
}

#[derive(NifMap)]
pub struct LootConfig {
    name: String,
    effects: Vec<Effect>,
}

#[derive(NifMap)]
pub struct Loot {
    name: String,
    size: u64,
    effect: Vec<Effect>,
    id: u64,
    position: (u64, u64),
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
                    effects,
                }
            })
            .collect()
    }
}
