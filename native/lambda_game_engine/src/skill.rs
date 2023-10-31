use rustler::{NifMap, NifTaggedEnum};
use serde::Deserialize;

use crate::{effect::Effect, projectile::ProjectileConfig};

#[derive(Deserialize)]
pub struct SkillConfigFile {
    name: String,
    cooldown_ms: u64,
    execution_duration_ms: u64,
    is_passive: bool,
    mechanics: Vec<SkillMechanicConfigFile>,
}

#[derive(NifMap, Clone)]
pub struct SkillConfig {
    pub name: String,
    pub cooldown_ms: u64,
    pub execution_duration_ms: u64,
    pub is_passive: bool,
    pub mechanics: Vec<SkillMechanic>,
}

#[derive(Deserialize)]
pub enum SkillMechanicConfigFile {
    GiveEffect(Vec<String>),
    Hit {
        damage: u64,
        range: u64,
        cone_angle: u64,
        on_hit_effects: Vec<String>,
    },
    SimpleShoot {
        projectile: String,
    },
    MultiShoot {
        projectile: String,
        count: u64,
        cone_angle: u64,
    },
    MoveToTarget {
        duration_ms: u64,
        max_range: u64,
    },
}

#[derive(NifTaggedEnum, Clone)]
pub enum SkillMechanic {
    GiveEffect(Vec<Effect>),
    Hit {
        damage: u64,
        range: u64,
        cone_angle: u64,
        on_hit_effects: Vec<Effect>,
    },
    SimpleShoot {
        projectile: ProjectileConfig,
    },
    MultiShoot {
        projectile: ProjectileConfig,
        count: u64,
        cone_angle: u64,
    },
    MoveToTarget {
        duration_ms: u64,
        max_range: u64,
    },
}

impl SkillConfig {
    pub(crate) fn from_config_file(
        skills: Vec<SkillConfigFile>,
        effects: &[Effect],
        projectiles: &[ProjectileConfig],
    ) -> Vec<SkillConfig> {
        skills
            .into_iter()
            .map(|config| {
                let mechanics =
                    SkillMechanic::from_config_file(config.mechanics, effects, projectiles);

                SkillConfig {
                    name: config.name.clone(),
                    cooldown_ms: config.cooldown_ms,
                    execution_duration_ms: config.execution_duration_ms,
                    is_passive: config.is_passive,
                    mechanics,
                }
            })
            .collect()
    }
}

impl SkillMechanic {
    pub(crate) fn from_config_file(
        mechanics: Vec<SkillMechanicConfigFile>,
        effects: &[Effect],
        projectiles: &[ProjectileConfig],
    ) -> Vec<SkillMechanic> {
        mechanics
            .into_iter()
            .map(|config| match config {
                SkillMechanicConfigFile::GiveEffect(config_effects) => {
                    let effects = effects
                        .iter()
                        .filter(|effect| config_effects.contains(&effect.name))
                        .cloned()
                        .collect();
                    SkillMechanic::GiveEffect(effects)
                }
                SkillMechanicConfigFile::Hit {
                    damage,
                    range,
                    cone_angle,
                    on_hit_effects,
                } => {
                    let effects = effects
                        .iter()
                        .filter(|effect| on_hit_effects.contains(&effect.name))
                        .cloned()
                        .collect();

                    SkillMechanic::Hit {
                        damage,
                        range,
                        cone_angle,
                        on_hit_effects: effects,
                    }
                }
                SkillMechanicConfigFile::SimpleShoot { projectile } => {
                    let projectile = projectiles
                        .iter()
                        .find(|projectile_config| projectile == projectile_config.name)
                        .unwrap_or_else(|| {
                            panic!(
                                "Shoot.projectile `{}` does not exist in projectiles config",
                                projectile
                            )
                        });

                    SkillMechanic::SimpleShoot {
                        projectile: projectile.clone(),
                    }
                }
                SkillMechanicConfigFile::MultiShoot {
                    projectile,
                    count,
                    cone_angle,
                } => {
                    let projectile = projectiles
                        .iter()
                        .find(|projectile_config| projectile == projectile_config.name)
                        .unwrap_or_else(|| {
                            panic!(
                                "Shoot.projectile `{}` does not exist in projectiles config",
                                projectile
                            )
                        });

                    SkillMechanic::MultiShoot {
                        projectile: projectile.clone(),
                        count,
                        cone_angle,
                    }
                }
                SkillMechanicConfigFile::MoveToTarget {
                    duration_ms,
                    max_range,
                } => SkillMechanic::MoveToTarget {
                    duration_ms,
                    max_range,
                },
            })
            .collect()
    }
}
