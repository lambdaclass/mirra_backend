use rustler::NifMap;
use serde::Deserialize;

use crate::{effect::Effect, map::Position};

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
    position: Position,
    direction_angle: f32,
    player_id: u64,
}

impl ProjectileConfig {
    pub(crate) fn from_config_file(
        projectiles: Vec<ProjectileConfigFile>,
        effects: &[Effect],
    ) -> Vec<ProjectileConfig> {
        projectiles
            .into_iter()
            .map(|config| {
                let effects = effects
                    .iter()
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

impl Projectile {
    pub fn new(
        id: u64,
        position: Position,
        direction_angle: f32,
        player_id: u64,
        config: &ProjectileConfig,
    ) -> Self {
        Projectile {
            name: config.name.clone(),
            damage: config.base_damage,
            speed: config.base_speed,
            size: config.base_speed,
            on_hit_effects: config.on_hit_effects.clone(),
            duration_ms: config.duration_ms,
            max_distance: config.max_distance,
            id,
            position,
            direction_angle,
            player_id,
        }
    }
}
