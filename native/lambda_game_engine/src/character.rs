use rustler::NifMap;
use serde::Deserialize;

#[derive(Deserialize, NifMap)]
pub struct CharacterConfig {
    name: String,
    active: bool,
    base_speed: u64,
    size: u64,
    skill_1: String,
    skill_2: String,
    skill_3: String,
    skill_4: String,
    skill_5: String,
}
