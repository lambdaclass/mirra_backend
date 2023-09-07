use rustler::{NifMap, NifTaggedEnum};
use serde::Deserialize;

#[derive(Deserialize, NifMap)]
pub struct Effect {
    name: String,
    duration_ms: u64,
    trigger_interval_ms: u64,
    mechanic: Mechanic,
}

#[derive(Deserialize, NifTaggedEnum)]
pub enum Mechanic {
    HealthChange(i64),
    MaxHealthPercentageChange(i64),
    DamagePercentageChange(i64),
    DefensePercentageChange(i64),
    SpeedPercentageChange(i64),
    SizePercentageChange(i64),
    CooldownPercentageChange(i64),
    Piercing,
    Disarm,
}
