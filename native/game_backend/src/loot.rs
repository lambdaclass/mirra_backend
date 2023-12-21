use rand::seq::SliceRandom;
use rustler::{NifMap, NifTaggedEnum};
use serde::Deserialize;

use crate::config::Config;
use crate::effect::Effect;
use crate::map::{self, Position};

#[derive(Deserialize, NifMap)]
pub struct LootFileConfig {
    name: String,
    size: f32,
    pickup_mechanic: PickupMechanic,
    effects: Vec<String>,
}

#[derive(NifMap)]
pub struct LootConfig {
    name: String,
    size: f32,
    pickup_mechanic: PickupMechanic,
    effects: Vec<Effect>,
}

#[derive(NifMap, Clone)]
pub struct Loot {
    pub name: String,
    pub size: f32,
    pub pickup_mechanic: PickupMechanic,
    pub effects: Vec<Effect>,
    pub id: u64,
    pub position: Position,
}

#[derive(Deserialize, NifTaggedEnum, Clone)]
pub enum PickupMechanic {
    CollisionToInventory,
    CollisionUse,
}

impl LootConfig {
    pub(crate) fn from_config_file(
        loots: Vec<LootFileConfig>,
        effects: &[Effect],
    ) -> Vec<LootConfig> {
        loots
            .into_iter()
            .map(|config| {
                let loot_effects: Vec<Effect> = effects
                    .iter()
                    .filter(|effect| config.effects.contains(&effect.name))
                    .cloned()
                    .collect();

                if config.effects.len() != loot_effects.len() {
                    panic!(
                        "Loot.effects one of `{}` does not exist in effects config",
                        config.effects.join(",")
                    );
                }

                if loot_effects.is_empty() {
                    panic!("Loot.effects can't be empty");
                }

                LootConfig {
                    name: config.name,
                    size: config.size,
                    pickup_mechanic: config.pickup_mechanic,
                    effects: loot_effects,
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
            pickup_mechanic: config.pickup_mechanic.clone(),
            effects: config.effects.clone(),
        }
    }
}

pub fn spawn_random_loot(config: &Config, id: u64) -> Option<Loot> {
    let rng = &mut rand::thread_rng();
    let position = map::random_position(config.game.width, config.game.height);

    config
        .loots
        .choose(rng)
        .map(|loot_config| Loot::new(id, position, loot_config))
}
