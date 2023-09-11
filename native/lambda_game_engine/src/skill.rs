use rustler::{NifMap, NifTaggedEnum};
use serde::Deserialize;

use crate::{effect::Effect, projectile::ProjectileConfig};

#[derive(Deserialize)]
pub struct SkillConfigFile {
    name: String,
    cooldown_ms: u64,
    is_passive: bool,
    mechanics: Vec<SkillMechanicConfigFile>,
}

#[derive(NifMap, Clone)]
pub struct SkillConfig {
    pub name: String,
    cooldown_ms: u64,
    is_passive: bool,
    mechanics: Vec<SkillMechanic>,
}

#[derive(Deserialize)]
pub enum SkillMechanicConfigFile {
    GiveEffect(Vec<String>),
    Hit { damage: u64, range: u64, cone_angle: u64, on_hit_effect: String },
    Shoot { projectile: String, autotarget: bool, autotarget_range: u64, autotarget_cone_angle: u64, multishot: bool, multishot_count: u64, multishot_cone_angle: u64 },
    MoveToTarget { duration_ms: u64, max_range: u64, collision_damage: u64 }
}

#[derive(NifTaggedEnum, Clone)]
pub enum SkillMechanic {
    GiveEffect(Vec<Effect>),
    Hit { damage: u64, range: u64, cone_angle: u64, on_hit_effect: Effect },
    Shoot { projectile: ProjectileConfig, autotarget: bool, autotarget_range: u64, autotarget_cone_angle: u64, multishot: bool, multishot_count: u64, multishot_cone_angle: u64 },
    MoveToTarget { duration_ms: u64, max_range: u64, collision_damage: u64 }
}

impl SkillConfig {
    pub(crate) fn from_config_file(skills: Vec<SkillConfigFile>, effects: &Vec<Effect>, projectiles: &Vec<ProjectileConfig>) -> Vec<SkillConfig> {
        skills.into_iter().map(|config| {
            let mechanics = SkillMechanic::from_config_file(config.mechanics, &effects, &projectiles);

            SkillConfig {
                name: config.name.clone(),
                cooldown_ms: config.cooldown_ms,
                is_passive: config.is_passive,
                mechanics,
            }
        })
        .collect()
    }
}

impl SkillMechanic {
    pub(crate) fn from_config_file(mechanics: Vec<SkillMechanicConfigFile>, effects: &Vec<Effect>, projectiles: &Vec<ProjectileConfig>) -> Vec<SkillMechanic> {
        mechanics.into_iter().map(|config| {
            match config {
                SkillMechanicConfigFile::GiveEffect(config_effects) => {
                    let effects = effects.iter().filter(|effect| config_effects.contains(&effect.name)).cloned().collect();
                    SkillMechanic::GiveEffect(effects)
                },
                SkillMechanicConfigFile::Hit { damage, range, cone_angle, on_hit_effect} => {
                    let effect = effects.iter().find(|effect| on_hit_effect == effect.name).expect(format!("Hit.on_hit_effect `{}` does not exist in effects config", on_hit_effect).as_str());
                    SkillMechanic::Hit {
                        damage,
                        range,
                        cone_angle,
                        on_hit_effect: effect.clone(),
                    }
                },
                SkillMechanicConfigFile::Shoot { projectile, autotarget, autotarget_range, autotarget_cone_angle, multishot, multishot_count, multishot_cone_angle } => {
                    let projectile = projectiles.iter().find(|projectile_config| projectile == projectile_config.name).expect(format!("Shoot.projectile `{}` does not exist in projectiles config", projectile).as_str());

                    SkillMechanic::Shoot {
                        projectile: projectile.clone(),
                        autotarget,
                        autotarget_range,
                        autotarget_cone_angle,
                        multishot,
                        multishot_count,
                        multishot_cone_angle,
                    }
                },
                SkillMechanicConfigFile::MoveToTarget { duration_ms, max_range, collision_damage } => {
                    SkillMechanic::MoveToTarget {
                        duration_ms,
                        max_range,
                        collision_damage,
                    }
                },
            }
        })
        .collect()
    }
}
