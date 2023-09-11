use rustler::NifMap;
use serde::Deserialize;

use crate::{effect::Effect, loot::LootConfig, skill::SkillConfig, projectile::ProjectileConfig, character::CharacterConfig};

#[derive(Deserialize, NifMap)]
pub struct Config {
    effects: Vec<Effect>,
    loots: Vec<LootConfig>,
    projectiles: Vec<ProjectileConfig>,
    skills: Vec<SkillConfig>,
    characters: Vec<CharacterConfig>,
}

pub fn parse_config(data: &str) -> Config {
    serde_json::from_str(data).unwrap()
}
