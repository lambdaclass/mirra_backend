use rustler::{NifMap, NifTaggedEnum};
use serde::Deserialize;

use crate::effect::Effect;

#[derive(Deserialize, NifMap)]
pub struct SkillConfig {
    name: String,
    cooldown_ms: u64,
    is_passive: bool,
    mechanics: Vec<SkillMechanic>,
}

#[derive(Deserialize, NifTaggedEnum)]
pub enum SkillMechanic {
    GiveEffect(Vec<String>),
    Hit { damage: u64, range: u64, cone_angle: u64, on_hit_effect: Effect },
    Shoot { projectile: String, autotarget: bool, autotarget_range: u64, autotarget_cone_angle: u64, multishot: bool, multishot_count: u64, multishot_cone_angle: u64 },
    MoveToTarget { duration_ms: u64, max_range: u64, collision_damage: u64 }
}
