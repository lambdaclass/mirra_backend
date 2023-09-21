use rustler::NifMap;
use serde::Deserialize;

use crate::effect::Effect;

#[derive(Deserialize)]
pub struct ProjectileConfigFile {
    name: String,
    base_damage: u64,
    base_speed: u64,
    base_size: u64,
    on_hit_effects: Vec<String>,
    duration_ms: u64,
    max_distance: u64,
}

#[derive(NifMap, Clone)]
pub struct ProjectileConfig {
    pub name: String,
    base_damage: u64,
    base_speed: u64,
    base_size: u64,
    on_hit_effects: Vec<Effect>,
    duration_ms: u64,
    max_distance: u64,
}

#[derive(NifMap)]
pub struct Projectile {
    name: String,
    damage: u64,
    speed: u64,
    size: u64,
    on_hit_effects: Vec<Effect>,
    duration_ms: u64,
    max_distance: u64,
    id: u64,
    position: (u64, u64),
    direction_angle: u64,
    player_id: u64,
}

impl ProjectileConfig {
    pub(crate) fn from_config_file(
        projectiles: Vec<ProjectileConfigFile>,
        effects: &Vec<Effect>,
    ) -> Vec<ProjectileConfig> {
        projectiles
            .into_iter()
            .map(|config| {
                let effects = effects
                    .into_iter()
                    .filter(|effect| config.on_hit_effects.contains(&effect.name))
                    .cloned()
                    .collect();

                ProjectileConfig {
                    name: config.name,
                    base_damage: config.base_damage,
                    base_speed: config.base_speed,
                    base_size: config.base_size,
                    on_hit_effects: effects,
                    duration_ms: config.duration_ms,
                    max_distance: config.max_distance,
                }
            })
            .collect()
    }
}
