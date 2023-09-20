use rustler::{NifMap, NifTaggedEnum};
use serde::Deserialize;

#[derive(Deserialize, NifMap, Clone)]
pub struct Effect {
    pub name: String,
    effect_time_type: TimeType,
    player_attributes: Vec<AttributeChange>,
    projectile_attributes: Vec<AttributeChange>
}

#[derive(Deserialize, NifMap, Clone)]
pub struct AttributeChange {
    attribute: String, // TODO: Can this be force to be certain things? Maybe an enum
    modifier: AttributeModifier,
    value: String, // TODO: Figure out how to do dynamic types here
}

#[derive(Deserialize, NifTaggedEnum, Clone)]
pub enum AttributeModifier {
    Additive, Multiplicative, Override
}

#[derive(Deserialize, NifTaggedEnum, Clone)]
pub enum TimeType {
    Instant,
    Permanent,
    Duration{duration_ms: u64},
    Periodic{instant_applicaiton: bool, interval_ms: u64, trigger_count: u64},
}
