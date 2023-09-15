use super::skills::*;
use super::time_utils::{u128_to_millis, MillisTime};
use rustler::NifTaggedEnum;
use std::collections::HashMap;
use std::str::FromStr;
use strum_macros::{Display, EnumString};

#[derive(Debug, Clone, rustler::NifTaggedEnum, EnumString, Display, PartialEq)]
pub enum Name {
    #[strum(ascii_case_insensitive)]
    Uma,
    #[strum(ascii_case_insensitive)]
    H4ck,
    #[strum(ascii_case_insensitive)]
    Muflus,
    #[strum(serialize = "DAgna", serialize = "Dagna")]
    DAgna,
}

#[derive(Debug, Clone, rustler::NifTaggedEnum, EnumString)]
pub enum Faction {
    #[strum(serialize = "ara", serialize = "Araban", ascii_case_insensitive)]
    Araban,
    #[strum(serialize = "kal", serialize = "Kaline", ascii_case_insensitive)]
    Kaline,
    #[strum(serialize = "oto", serialize = "Otobi", ascii_case_insensitive)]
    Otobi,
    #[strum(serialize = "mer", serialize = "Merliot", ascii_case_insensitive)]
    Merliot,
}

#[derive(NifTaggedEnum, Debug, Clone, EnumString, Display)]
pub enum Class {
    #[strum(serialize = "hun", serialize = "Hunter", ascii_case_insensitive)]
    Hunter,
    #[strum(serialize = "war", serialize = "Warrior", ascii_case_insensitive)]
    Warrior,
    #[strum(serialize = "ass", serialize = "Assassin", ascii_case_insensitive)]
    Assassin,
    #[strum(serialize = "wiz", serialize = "Wizard", ascii_case_insensitive)]
    Wizard,
}

#[derive(Debug, Clone, rustler::NifStruct)]
#[module = "LambdaGameEngine.MyrraEngine.Character"]
pub struct Character {
    pub class: Class,
    pub id: u64,
    pub active: bool,
    pub faction: Faction,
    pub name: Name,
    pub base_speed: u64,
    pub skill_basic: Skill,
    pub skill_1: Skill,
    pub skill_2: Skill,
    pub skill_3: Skill,
    pub skill_4: Skill,
    pub body_size: f64,
}

impl Character {
    pub fn new(
        class: Class,
        base_speed: u64,
        name: &Name,
        skill_basic: Skill,
        skill_1: Skill,
        skill_2: Skill,
        skill_3: Skill,
        skill_4: Skill,
        active: bool,
        id: u64,
        faction: Faction,
        body_size: f64,
    ) -> Self {
        Self {
            class,
            name: name.clone(),
            active,
            id,
            faction,
            base_speed,
            skill_basic,
            skill_1,
            skill_2,
            skill_3,
            skill_4,
            body_size,
        }
    }
    // NOTE:
    // A possible improvement here is that elixir sends a Json and
    // we deserialize it here with Serde
    pub fn from_config_map(
        config: &HashMap<String, String>,
        skills: &[Skill],
    ) -> Result<Character, String> {
        let name = get_key(config, "Name")?;
        let id = get_key(config, "Id")?;
        let active = get_key(config, "Active")?;
        let class = get_key(config, "Class")?;
        let faction = get_key(config, "Faction")?;
        let base_speed = get_key(config, "BaseSpeed")?;
        let skill_basic = get_key(config, "SkillBasic")?;
        let skill_1 = get_key(config, "SkillActive1")?;
        let skill_2 = get_key(config, "SkillActive2")?;
        let skill_3 = get_key(config, "SkillDash")?;
        let skill_4 = get_key(config, "SkillUltimate")?;
        let body_size = get_key(config, "BodySize")?;
        Ok(Self {
            active: parse_character_attribute::<u64>(&active)? != 0,
            base_speed: parse_character_attribute(&base_speed)?,
            class: parse_character_attribute(&class)?,
            faction: parse_character_attribute(&faction)?,
            id: parse_character_attribute(&id)?,
            name: parse_character_attribute(&name)?,
            skill_basic: get_skill(&skills, &skill_basic)?,
            skill_1: get_skill(&skills, &skill_1)?,
            skill_2: get_skill(&skills, &skill_2)?,
            skill_3: get_skill(&skills, &skill_3)?,
            skill_4: get_skill(&skills, &skill_4)?,
            body_size: parse_character_attribute(&body_size)?,
        })
    }

    pub fn attack_dmg_basic_skill(&self) -> u32 {
        self.skill_basic.damage
    }
    pub fn attack_dmg_skill_1(&self) -> u32 {
        self.skill_1.damage
    }
    pub fn attack_dmg_skill_2(&self) -> u32 {
        self.skill_2.damage
    }
    pub fn attack_dmg_skill_3(&self) -> u32 {
        self.skill_3.damage
    }
    pub fn _attack_dmg_skill_4(&self) -> u32 {
        self.skill_4.damage
    }

    pub fn cooldown_basic_skill(&self) -> MillisTime {
        u128_to_millis(self.skill_basic.cooldown_ms as u128)
    }

    pub fn cooldown_skill_1(&self) -> MillisTime {
        u128_to_millis(self.skill_1.cooldown_ms as u128)
    }

    pub fn cooldown_skill_2(&self) -> MillisTime {
        u128_to_millis(self.skill_2.cooldown_ms as u128)
    }

    pub fn cooldown_skill_3(&self) -> MillisTime {
        u128_to_millis(self.skill_3.cooldown_ms as u128)
    }

    pub fn cooldown_skill_4(&self) -> MillisTime {
        u128_to_millis(self.skill_4.cooldown_ms as u128)
    }

    pub fn duration_basic_skill(&self) -> MillisTime {
        u128_to_millis(self.skill_basic.duration as u128)
    }

    pub fn duration_skill_1(&self) -> MillisTime {
        u128_to_millis(self.skill_1.duration as u128)
    }

    pub fn duration_skill_2(&self) -> MillisTime {
        u128_to_millis(self.skill_2.duration as u128)
    }

    pub fn duration_skill_3(&self) -> MillisTime {
        u128_to_millis(self.skill_3.duration as u128)
    }

    pub fn duration_skill_4(&self) -> MillisTime {
        u128_to_millis(self.skill_4.duration as u128)
    }

    pub fn par_1_basic_skill(&self) -> u32 {
        self.skill_basic.par1
    }
    pub fn par_1_skill_1(&self) -> u32 {
        self.skill_1.par1
    }
    pub fn _par_1_skill_2(&self) -> u32 {
        self.skill_2.par1
    }
    pub fn _par_1_skill_3(&self) -> u32 {
        self.skill_3.par1
    }
    pub fn _par_1_skill_4(&self) -> u32 {
        self.skill_4.par1
    }
}

//TODO: This character is broken, it has basic skill as all skills
impl Default for Character {
    fn default() -> Self {
        Character::new(
            Class::Hunter,
            50,
            &Name::H4ck,
            Skill::default(),
            Skill::default(),
            Skill::default(),
            Skill::default(),
            Skill::default(),
            true,
            1,
            Faction::Araban,
            100.0,
        )
    }
}
fn get_key(config: &HashMap<String, String>, key: &str) -> Result<String, String> {
    config
        .get(key)
        .ok_or(format!("Missing key: {:?}", key))
        .map(|s| s.to_string())
}
fn parse_character_attribute<T: FromStr>(to_parse: &str) -> Result<T, String> {
    let parsed = T::from_str(&to_parse);
    match parsed {
        Ok(parsed) => Ok(parsed),
        Err(_parsing_error) => Err(format!(
            "Could not parse value: {:?} for Character Type: {}",
            to_parse,
            std::any::type_name::<T>()
        )),
    }
}

fn get_skill(skills: &[Skill], skill_name: &str) -> Result<Skill, String> {
    skills
        .iter()
        .find(|skill| skill.name == skill_name)
        .ok_or(format!("Skill '{}' does not exist", skill_name))
        .map(|skill| skill.clone())
}
