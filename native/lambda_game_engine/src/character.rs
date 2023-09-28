use std::collections::HashMap;

use rustler::NifMap;
use serde::Deserialize;

use crate::skill::SkillConfig;

#[derive(Deserialize)]
pub struct CharacterConfigFile {
    name: String,
    active: bool,
    base_speed: u64,
    base_size: u64,
    skills: HashMap<String, String>,
}

#[derive(NifMap, Clone)]
pub struct CharacterConfig {
    pub name: String,
    pub active: bool,
    pub base_speed: u64,
    pub base_size: u64,
    pub skills: HashMap<String, SkillConfig>,
}

impl CharacterConfig {
    pub(crate) fn from_config_file(
        characters: Vec<CharacterConfigFile>,
        skills: &Vec<SkillConfig>,
    ) -> Vec<CharacterConfig> {
        characters
            .into_iter()
            .map(|config| {
                let mut character_skills = HashMap::new();
                for (skill_id, skill_name) in config.skills.iter() {
                    let skill = find_skill(skill_name.to_string(), skills);
                    character_skills.insert(skill_id.to_string(), skill);
                }

                CharacterConfig {
                    name: config.name,
                    active: config.active,
                    base_speed: config.base_speed,
                    base_size: config.base_size,
                    skills: character_skills,
                }
            })
            .collect()
    }
}

fn find_skill(skill_name: String, skills: &Vec<SkillConfig>) -> SkillConfig {
    skills
        .iter()
        .find(|skill| skill_name == skill.name)
        .expect(format!("Skill `{}` does not exist in skills config", skill_name).as_str())
        .clone()
}
