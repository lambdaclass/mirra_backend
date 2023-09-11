use rustler::NifMap;
use serde::Deserialize;

use crate::effect::Effect;

#[derive(Deserialize, NifMap)]
pub struct LootConfig {
    name: String,
    effects: Vec<String>,
}

#[derive(NifMap)]
pub struct Loot {
    name: String,
    size: u64,
    effect: Vec<Effect>,
    id: u64,
    position: (u64, u64),
}
