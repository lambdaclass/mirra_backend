use rustler::NifMap;
use serde::Deserialize;

use crate::skill::SkillConfig;

#[derive(Deserialize)]
pub struct CharacterConfigFile {
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

#[derive(NifMap)]
pub struct CharacterConfig {
    name: String,
    active: bool,
    base_speed: u64,
    size: u64,
    skill_1: SkillConfig,
    skill_2: SkillConfig,
    skill_3: SkillConfig,
    skill_4: SkillConfig,
    skill_5: SkillConfig,
}

impl CharacterConfig {
    pub(crate) fn from_config_file(
        characters: Vec<CharacterConfigFile>,
        skills: &Vec<SkillConfig>,
    ) -> Vec<CharacterConfig> {
        characters
            .into_iter()
            .map(|config| {
                let skill_1 = find_skill(config.skill_1, skills);
                let skill_2 = find_skill(config.skill_2, skills);
                let skill_3 = find_skill(config.skill_3, skills);
                let skill_4 = find_skill(config.skill_4, skills);
                let skill_5 = find_skill(config.skill_5, skills);

                CharacterConfig {
                    name: config.name,
                    active: config.active,
                    base_speed: config.base_speed,
                    size: config.size,
                    skill_1,
                    skill_2,
                    skill_3,
                    skill_4,
                    skill_5,
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
