use rustler::{NifMap, NifTaggedEnum};
use serde::Deserialize;

#[derive(Deserialize, NifMap, Clone)]
pub struct Effect {
    pub name: String,
    pub effect_time_type: TimeType,
    pub player_attributes: Vec<AttributeChange>,
    pub projectile_attributes: Vec<AttributeChange>,
}

#[derive(Deserialize, NifMap, Clone)]
pub struct AttributeChange {
    pub attribute: String, // TODO: Can this be force to be certain things? Maybe an enum
    pub modifier: AttributeModifier,
    pub value: String, // TODO: Figure out how to do dynamic types here
}

#[derive(Deserialize, NifTaggedEnum, Clone)]
pub enum AttributeModifier {
    Additive,
    Multiplicative,
    Override,
}

#[derive(Deserialize, NifTaggedEnum, Clone, PartialEq)]
pub enum TimeType {
    Instant,
    Permanent,
    Duration {
        duration_ms: u64,
    },
    Periodic {
        instant_applicaiton: bool,
        interval_ms: u64,
        trigger_count: u64,
        #[serde(skip_deserializing)]
        time_since_last_trigger: u64, // Default value is 0
    },
}
