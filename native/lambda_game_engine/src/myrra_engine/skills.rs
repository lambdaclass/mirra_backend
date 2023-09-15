use std::{collections::HashMap, str::FromStr};

use rustler::NifStruct;

#[derive(Debug, Clone, NifStruct)]
#[module = "LambdaGameEngine.MyrraEngine.Skill"]
pub struct Skill {
    pub name: String,
    pub cooldown_ms: u64,
    pub damage: u32,
    pub duration: u64,
    pub skill_range: f64,
    pub par1: u32,
    pub par1desc: String, // temp. See #764
    pub par2: u32,
    pub par2desc: String, // temp
    pub par3: u32,
    pub par3desc: String, // temp
    pub par4: u32,
    pub par4desc: String, // temp
    pub par5: u32,
    pub par5desc: String, // temp
    pub angle: u64,
}

impl Skill {
    pub fn from_config_map(config: &HashMap<String, String>) -> Result<Skill, String> {
        let name = get_skill_field(config, "Name")?;
        let cooldown_ms = get_skill_field(config, "Cooldown")?;
        let damage = get_skill_field(config, "Damage")?;
        let duration = get_skill_field(config, "Duration")?;
        let skill_range = get_skill_field(config, "SkillRange")?;
        let par1 = get_skill_field(config, "Par1")?;
        let par1desc = get_skill_field(config, "Par1Desc")?;
        let par2 = get_skill_field(config, "Par2")?;
        let par2desc = get_skill_field(config, "Par2Desc")?;
        let par3 = get_skill_field(config, "Par3")?;
        let par3desc = get_skill_field(config, "Par3Desc")?;
        let par4 = get_skill_field(config, "Par4")?;
        let par4desc = get_skill_field(config, "Par4Desc")?;
        let par5 = get_skill_field(config, "Par5")?;
        let par5desc = get_skill_field(config, "Par5Desc")?;
        let angle = get_skill_field(config, "Angle")?;
        Ok(Self {
            name,
            cooldown_ms,
            damage,
            duration,
            skill_range,
            par1,
            par1desc,
            par2,
            par2desc,
            par3,
            par3desc,
            par4,
            par4desc,
            par5,
            par5desc,
            angle,
        })
    }
}

impl Default for Skill {
    fn default() -> Self {
        Skill {
            name: "Slingshot".to_string(),
            cooldown_ms: 1000,
            damage: 10,
            duration: 0,
            skill_range: 100.0,
            par1: 0,
            par1desc: "".to_string(),
            par2: 0,
            par2desc: "".to_string(),
            par3: 0,
            par3desc: "".to_string(),
            par4: 0,
            par4desc: "".to_string(),
            par5: 0,
            par5desc: "".to_string(),
            angle: 10,
        }
    }
}

pub fn build_from_config(skills_config: &[HashMap<String, String>]) -> Result<Vec<Skill>, String> {
    skills_config.iter().map(Skill::from_config_map).collect()
}

fn get_skill_field<T: FromStr>(config: &HashMap<String, String>, key: &str) -> Result<T, String> {
    let value_result = config
        .get(key)
        .ok_or(format!("Missing key: {:?}", key))
        .map(|s| s.to_string());

    match value_result {
        Ok(value) => parse_attribute(&value),
        Err(error) => Err(format!("Error parsing '{}'\n{}", key, error)),
    }
}

fn parse_attribute<T: FromStr>(to_parse: &str) -> Result<T, String> {
    let parsed = T::from_str(&to_parse);
    match parsed {
        Ok(parsed) => Ok(parsed),
        Err(_parsing_error) => Err(format!(
            "Could not parse value: '{}' for Skill Type: {}",
            to_parse,
            std::any::type_name::<T>()
        )),
    }
}
