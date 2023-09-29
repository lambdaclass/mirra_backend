use rand::Rng;
use rand::seq::SliceRandom;
use rustler::NifMap;
use serde::Deserialize;

use crate::config::Config;
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
    pub name: String,
    pub size: u64,
    pub effects: Vec<Effect>,
    pub id: u64,
    pub position: Position,
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

impl Loot {
    pub fn new(id: u64, position: Position, config: &LootConfig) -> Self {
        Loot {
            id,
            position,
            name: config.name.clone(),
            size: config.size,
            effects: config.effects.clone(),
        }
    }
}

pub fn spawn_random_loot(config: &Config, id: u64) -> Option<Loot> {
    let rng = &mut rand::thread_rng();
    let bound_x = (config.game.width / 2) as i64;
    let bound_y = (config.game.height / 2) as i64;

    let position = Position {
        x: rng.gen_range(-bound_x..bound_x),
        y: rng.gen_range(-bound_y..bound_y),
    };

    config.loots
    .choose(rng)
    .map(|loot_config| Loot::new(id, position, loot_config))
}
