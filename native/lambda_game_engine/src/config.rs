use rustler::NifMap;
use serde::Deserialize;

use crate::{effect::Effect, loot::{LootConfig, LootFileConfig}, skill::{SkillConfig, SkillConfigFile}, projectile::{ProjectileConfig, ProjectileConfigFile}, character::{CharacterConfig, CharacterConfigFile}};

#[derive(Deserialize)]
pub struct ConfigFile {
    effects: Vec<Effect>,
    loots: Vec<LootFileConfig>,
    projectiles: Vec<ProjectileConfigFile>,
    skills: Vec<SkillConfigFile>,
    characters: Vec<CharacterConfigFile>,
}

#[derive(NifMap)]
pub struct Config {
    effects: Vec<Effect>,
    loots: Vec<LootConfig>,
    projectiles: Vec<ProjectileConfig>,
    skills: Vec<SkillConfig>,
    characters: Vec<CharacterConfig>,
}

pub fn parse_config(data: &str) -> Config {
    let config_file: ConfigFile = serde_json::from_str(data).unwrap();
    let effects = config_file.effects;
    let loots = LootConfig::from_config_file(config_file.loots, &effects);
    let projectiles = ProjectileConfig::from_config_file(config_file.projectiles, &effects);
    let skills = SkillConfig::from_config_file(config_file.skills, &effects, &projectiles);
    let characters = CharacterConfig::from_config_file(config_file.characters, &skills);

    Config {
        effects,
        loots,
        projectiles,
        skills,
        characters,
     }
}
