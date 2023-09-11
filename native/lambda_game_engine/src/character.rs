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
                let skill_1 = skills
                    .iter()
                    .find(|skill| config.skill_1 == skill.name)
                    .expect(
                        format!(
                            "Character `{}` skill_1 `{}` does not exist in skills config",
                            config.name, config.skill_1
                        )
                        .as_str(),
                    );
                let skill_2 = skills
                    .iter()
                    .find(|skill| config.skill_2 == skill.name)
                    .expect(
                        format!(
                            "Character `{}` skill_2 `{}` does not exist in skills config",
                            config.name, config.skill_2
                        )
                        .as_str(),
                    );
                let skill_3 = skills
                    .iter()
                    .find(|skill| config.skill_3 == skill.name)
                    .expect(
                        format!(
                            "Character `{}` skill_3 `{}` does not exist in skills config",
                            config.name, config.skill_3
                        )
                        .as_str(),
                    );
                let skill_4 = skills
                    .iter()
                    .find(|skill| config.skill_4 == skill.name)
                    .expect(
                        format!(
                            "Character `{}` skill_4 `{}` does not exist in skills config",
                            config.name, config.skill_4
                        )
                        .as_str(),
                    );
                let skill_5 = skills
                    .iter()
                    .find(|skill| config.skill_5 == skill.name)
                    .expect(
                        format!(
                            "Character `{}` skill_5 `{}` does not exist in skills config",
                            config.name, config.skill_5
                        )
                        .as_str(),
                    );

                CharacterConfig {
                    name: config.name,
                    active: config.active,
                    base_speed: config.base_speed,
                    size: config.size,
                    skill_1: skill_1.clone(),
                    skill_2: skill_2.clone(),
                    skill_3: skill_3.clone(),
                    skill_4: skill_4.clone(),
                    skill_5: skill_5.clone(),
                }
            })
            .collect()
    }
}
