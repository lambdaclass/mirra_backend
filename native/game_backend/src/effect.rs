use rustler::{NifMap, NifTaggedEnum};
use serde::Deserialize;

#[derive(Deserialize, NifMap, Clone, Debug)]
pub struct Effect {
    pub name: String,
    pub is_reversable: bool,
    pub effect_time_type: TimeType,
    pub player_attributes: Vec<AttributeChange>,
    pub projectile_attributes: Vec<AttributeChange>,
    pub skills_keys_to_execute: Vec<String>,
}

#[derive(Deserialize, NifMap, Clone, Debug)]
pub struct AttributeChange {
    pub attribute: String, // TODO: Can this be force to be certain things? Maybe an enum
    pub modifier: AttributeModifier,
    pub value: String, // TODO: Figure out how to do dynamic types here
}

#[derive(Deserialize, NifTaggedEnum, Clone, Debug)]
pub enum AttributeModifier {
    Additive,
    Multiplicative,
    Override,
}


#[derive(Deserialize, NifTaggedEnum, Clone, PartialEq, Eq, Debug)]

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

pub fn modify_attribute(attribute_value: &mut u64, change: &AttributeChange) {
    match change.modifier {
        AttributeModifier::Additive => {
            *attribute_value =
                (*attribute_value).saturating_add_signed(change.value.parse::<i64>().unwrap())
        }
        AttributeModifier::Multiplicative => {
            *attribute_value =
                ((*attribute_value as f64) * change.value.parse::<f64>().unwrap()) as u64
        }
        AttributeModifier::Override => *attribute_value = change.value.parse::<u64>().unwrap(),
    }
}
