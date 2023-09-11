use rustler::NifMap;
use serde::Deserialize;

use crate::effect::Effect;

#[derive(Deserialize)]
pub struct ProjectileConfigFile {
    name: String,
    damage: u64,
    speed: u64,
    size: u64,
    on_hit_effect: Option<String>,
    duration_ms: u64,
    max_distance: u64,
}

#[derive(NifMap, Clone)]
pub struct ProjectileConfig {
    pub name: String,
    damage: u64,
    speed: u64,
    size: u64,
    on_hit_effect: Option<Effect>,
    duration_ms: u64,
    max_distance: u64,
}

#[derive(NifMap)]
pub struct Projectile {
    name: String,
    damage: u64,
    speed: u64,
    size: u64,
    on_hit_effect: Effect,
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
        projectiles.into_iter().map(|config| {
            let effect = match config.on_hit_effect {
                None => None,
                Some(config_on_hit_effect) => {
                    let option_effect = effects.into_iter().find(|effect| config_on_hit_effect == effect.name).expect(format!("Projectile `{}` on_hit_effect `{}` does not exist in effects config", config.name, config_on_hit_effect).as_str());
                    Some(option_effect.clone())
                }
            };

            ProjectileConfig {
                name: config.name,
                damage: config.damage,
                speed: config.speed,
                size: config.size,
                on_hit_effect: effect,
                duration_ms: config.duration_ms,
                max_distance: config.max_distance,
            }
        })
        .collect()
    }
}
