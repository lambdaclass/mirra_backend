use rustler::{NifMap, NifTaggedEnum};
use serde::Deserialize;

use crate::{
    character::{CharacterConfig, CharacterConfigFile},
    effect::Effect,
    game::{GameConfig, GameConfigFile},
    loot::{LootConfig, LootFileConfig},
    map::Position,
    projectile::{ProjectileConfig, ProjectileConfigFile},
    skill::{SkillConfig, SkillConfigFile},
};

#[derive(Deserialize)]
pub struct ConfigFile {
    effects: Vec<Effect>,
    loots: Vec<LootFileConfig>,
    projectiles: Vec<ProjectileConfigFile>,
    skills: Vec<SkillConfigFile>,
    characters: Vec<CharacterConfigFile>,
    game: GameConfigFile,
}

#[derive(NifMap)]
pub struct Config {
    effects: Vec<Effect>,
    pub loots: Vec<LootConfig>,
    projectiles: Vec<ProjectileConfig>,
    skills: Vec<SkillConfig>,
    characters: Vec<CharacterConfig>,
    pub game: GameConfig,
}

#[derive(Deserialize, NifTaggedEnum, Clone, PartialEq)]
pub enum CollisionableType {
    Circle,
    Rectangle,
}

#[derive(Deserialize)]
pub struct MapCollisionablesFile {
    map_collisionables: Vec<MapCollisionable>,
}

#[derive(Deserialize, NifMap)]
pub struct MapCollisionable {
    pub id: u64,
    pub collisionable_type: CollisionableType,
    pub position: Position,
    pub radius: u64,
}

impl Config {
    pub fn find_character(&self, name: String) -> Option<CharacterConfig> {
        self.characters
            .iter()
            .find(|character_config| character_config.active && character_config.name == name)
            .cloned()
    }

    pub fn find_effect(&self, name: String) -> Option<&Effect> {
        self.effects.iter().find(|effect| effect.name == name)
    }
}

pub fn parse_config(data: &str) -> Config {
    let config_file: ConfigFile = serde_json::from_str(data).unwrap();
    let effects = config_file.effects;
    let loots = LootConfig::from_config_file(config_file.loots, &effects);
    let projectiles = ProjectileConfig::from_config_file(config_file.projectiles, &effects);
    let skills = SkillConfig::from_config_file(config_file.skills, &effects, &projectiles);
    let characters = CharacterConfig::from_config_file(config_file.characters, &skills);
    let game = GameConfig::from_config_file(config_file.game, &effects);

    Config {
        effects,
        loots,
        projectiles,
        skills,
        characters,
        game,
    }
}

pub fn parse_map_collisionables(data: &str) -> Vec<MapCollisionable> {
    let map_collisionables_file: MapCollisionablesFile = serde_json::from_str(data).unwrap();
    map_collisionables_file.map_collisionables
}
