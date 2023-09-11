use rustler::{NifMap, NifTaggedEnum};
use serde::Deserialize;

#[derive(Deserialize, NifMap, Clone)]
pub struct Effect {
    pub name: String,
    duration_ms: u64,
    trigger_interval_ms: u64,
    mechanic: Mechanic,
}

#[derive(Deserialize, NifTaggedEnum, Clone)]
pub enum Mechanic {
    HealthChange(i64),
    MaxHealthPercentageChange(i64),
    DamagePercentageChange(i64),
    DefensePercentageChange(i64),
    SpeedPercentageChange(i64),
    SizePercentageChange(i64),
    CooldownMaxPercentageChange(i64),
    ProjectileSpeedPercentageChange(i64),
    Piercing,
    Disarm,
}
