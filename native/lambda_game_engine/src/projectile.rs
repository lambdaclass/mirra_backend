use rustler::NifMap;
use serde::Deserialize;

use crate::effect::Effect;

#[derive(Deserialize, NifMap)]
pub struct ProjectileConfig {
    name: String,
    damage: u64,
    speed: u64,
    size: u64,
    on_hit_effect: String,
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
