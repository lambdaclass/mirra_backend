use rustler::NifMap;
use serde::Deserialize;

use crate::effect::Effect;

#[derive(Deserialize, NifMap)]
pub struct Config {
    effects: Vec<Effect>,
}

pub fn parse_config(data: &str) -> Config {
    serde_json::from_str(data).unwrap()
}
