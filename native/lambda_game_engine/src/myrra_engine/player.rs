use super::character::{Character, Name};
use super::time_utils::{millis_to_u128, sub_millis, u128_to_millis, MillisTime};
use super::utils::RelativePosition;
use rand::Rng;
use rustler::NifStruct;
use rustler::NifUnitEnum;
use std::collections::HashMap;

#[derive(Debug, Clone, Copy, NifStruct)]
#[module = "LambdaGameEngine.MyrraEngine.Player"]
pub struct EffectData {
    pub time_left: MillisTime,
    pub ends_at: MillisTime,
    pub duration: MillisTime,
    pub direction: Option<RelativePosition>,
    pub position: Option<Position>,
    pub triggered_at: MillisTime,
    pub caused_by: u64,
    pub caused_to: u64,
    pub damage: u32,
}

pub type StatusEffects = HashMap<Effect, EffectData>;

#[derive(rustler::NifTaggedEnum, Debug, Hash, Clone, Copy, PartialEq, Eq)]
pub enum Effect {
    Petrified,
    Disarmed,
    DenialOfService,
    Raged,
    NeonCrashing,
    Leaping,
    OutOfArea,
    ElnarMark,
    YugenMark,
    XandaMark,
    XandaMarkOwner,
    Poisoned,
    Slowed,
    FieryRampage,
    Burned,
    Scherzo,
    DanseMacabre,
    Paralyzed,
}
impl Effect {
    pub fn is_crowd_control(&self) -> bool {
        match self {
            Effect::Petrified | Effect::Disarmed => true,
            _ => false,
        }
    }
}

/*
    Note: To track cooldowns we are storing the last system time when the ability/attack
    was used. This is not ideal, because system time is unreliable, but storing an `Instant`
    as a field on players does not work because it can't be encoded between Elixir and Rust.
*/

#[derive(Debug, Clone, NifStruct)]
#[module = "LambdaGameEngine.MyrraEngine.Player"]
pub struct Player {
    pub id: u64,
    pub health: i64,
    pub position: Position,
    pub status: Status,
    pub character: Character,
    pub action: PlayerAction,
    pub aoe_position: Position,
    pub kill_count: u64,
    pub death_count: u64,
    // How many seconds are left until the
    // cooldown is over.
    pub basic_skill_cooldown_left: MillisTime,
    pub skill_1_cooldown_left: MillisTime,
    pub skill_2_cooldown_left: MillisTime,
    pub skill_3_cooldown_left: MillisTime,
    pub skill_4_cooldown_left: MillisTime,
    // Timestamp when the cooldown started.
    pub basic_skill_started_at: MillisTime,
    pub skill_1_started_at: MillisTime,
    pub skill_2_started_at: MillisTime,
    pub skill_3_started_at: MillisTime,
    pub skill_4_started_at: MillisTime,
    pub basic_skill_ends_at: MillisTime,
    pub skill_1_ends_at: MillisTime,
    pub skill_2_ends_at: MillisTime,
    pub skill_3_ends_at: MillisTime,
    pub skill_4_ends_at: MillisTime,
    // This field is redundant given that
    // we have the Character filed, this his
    // hopefully temporary and to tell
    // the client which character is being used.
    pub character_name: String,
    pub effects: StatusEffects,
    pub direction: RelativePosition,
    pub body_size: f64,
}

#[derive(Debug, Clone, NifUnitEnum)]
pub enum Status {
    ALIVE,
    DEAD,
    DISCONNECTED,
}

#[derive(rustler::NifTaggedEnum, Debug, Hash, Clone, PartialEq, Eq)]
pub enum PlayerAction {
    NOTHING,
    ATTACKING,
    ATTACKINGAOE,
    STARTINGSKILL1,
    STARTINGSKILL2,
    STARTINGSKILL3,
    STARTINGSKILL4,
    EXECUTINGSKILL1,
    EXECUTINGSKILL2,
    EXECUTINGSKILL3,
    EXECUTINGSKILL4,
    MOVING,
}

#[derive(Debug, Copy, Clone, NifStruct, PartialEq)]
#[module = "LambdaGameEngine.MyrraEngine.Position"]
pub struct Position {
    pub x: usize,
    pub y: usize,
}

impl Player {
    pub fn new(id: u64, health: i64, position: Position, character: Character) -> Self {
        Self {
            id,
            health,
            position,
            status: Status::ALIVE,
            character_name: character.name.to_string(),
            body_size: character.body_size,
            character,
            action: PlayerAction::NOTHING,
            aoe_position: Position::new(0, 0),
            kill_count: 0,
            death_count: 0,
            basic_skill_cooldown_left: MillisTime { high: 0, low: 0 },
            skill_1_cooldown_left: MillisTime { high: 0, low: 0 },
            skill_2_cooldown_left: MillisTime { high: 0, low: 0 },
            skill_3_cooldown_left: MillisTime { high: 0, low: 0 },
            skill_4_cooldown_left: MillisTime { high: 0, low: 0 },
            basic_skill_started_at: MillisTime { high: 0, low: 0 },
            skill_1_started_at: MillisTime { high: 0, low: 0 },
            skill_2_started_at: MillisTime { high: 0, low: 0 },
            skill_3_started_at: MillisTime { high: 0, low: 0 },
            skill_4_started_at: MillisTime { high: 0, low: 0 },
            basic_skill_ends_at: MillisTime { high: 0, low: 0 },
            skill_1_ends_at: MillisTime { high: 0, low: 0 },
            skill_2_ends_at: MillisTime { high: 0, low: 0 },
            skill_3_ends_at: MillisTime { high: 0, low: 0 },
            skill_4_ends_at: MillisTime { high: 0, low: 0 },
            effects: HashMap::new(),
            direction: RelativePosition::new(0., 0.),
        }
    }
    pub fn modify_health(self: &mut Self, hp_points: i64) {
        if matches!(self.status, Status::ALIVE) {
            self.health = self.health.saturating_add(self.calculate_damage(hp_points));
            if self.health <= 0 {
                self.status = Status::DEAD;
                self.death_count += 1;
                self.effects.clear();
            }
        }
    }

    pub fn calculate_damage(self: &Self, hp_points: i64) -> i64 {
        let mut damage = hp_points;
        if self.character.name == Name::Uma && self.has_active_effect(&Effect::XandaMarkOwner) {
            damage = damage / 2;
        }
        if self.has_active_effect(&Effect::FieryRampage) {
            damage = damage * 3 / 4;
        }
        damage
    }

    pub fn get_mirrored_player_id(self: &mut Self) -> Option<u64> {
        if self.character.name == Name::Uma {
            match self.effects.get(&Effect::XandaMarkOwner) {
                Some(effect) => {
                    return Some(effect.caused_to);
                }
                None => return None,
            }
        }
        None
    }

    pub fn add_kills(self: &mut Self, kills: u64) {
        self.kill_count += kills;
    }

    pub fn basic_skill_damage(&self) -> u32 {
        let mut damage = self.character.attack_dmg_basic_skill();
        if self.has_active_effect(&Effect::Raged) {
            damage += 10_u32;
        }

        damage
    }
    pub fn skill_1_damage(&self) -> u32 {
        let mut damage = self.character.attack_dmg_skill_1();
        if self.has_active_effect(&Effect::Raged) {
            damage += 10_u32;
        }

        damage
    }
    pub fn skill_2_damage(&self) -> u32 {
        return self.character.attack_dmg_skill_2();
    }

    pub fn skill_3_damage(&self) -> u32 {
        return self.character.attack_dmg_skill_3();
    }

    pub fn basic_skill_range(&self) -> f64 {
        self.character.skill_basic.skill_range
    }
    pub fn skill_1_range(&self) -> f64 {
        self.character.skill_1.skill_range
    }
    pub fn _skill_2_range(&self) -> f64 {
        self.character.skill_2.skill_range
    }
    pub fn skill_3_range(&self) -> f64 {
        self.character.skill_3.skill_range
    }
    pub fn _skill_4_range(&self) -> f64 {
        self.character.skill_4.skill_range
    }

    pub fn basic_skill_angle(&self) -> u64 {
        self.character.skill_basic.angle
    }
    pub fn skill_1_angle(&self) -> u64 {
        self.character.skill_1.angle
    }
    pub fn skill_2_angle(&self) -> u64 {
        self.character.skill_2.angle
    }
    pub fn _skill_3_angle(&self) -> u64 {
        self.character.skill_3.angle
    }
    pub fn _skill_4_angle(&self) -> u64 {
        self.character.skill_4.angle
    }

    pub fn basic_skill_cooldown(&self) -> MillisTime {
        self.modify_cooldown(self.character.cooldown_basic_skill())
    }
    pub fn skill_1_cooldown(&self) -> MillisTime {
        self.modify_cooldown(self.character.cooldown_skill_1())
    }
    pub fn skill_2_cooldown(&self) -> MillisTime {
        self.modify_cooldown(self.character.cooldown_skill_2())
    }
    pub fn skill_3_cooldown(&self) -> MillisTime {
        self.modify_cooldown(self.character.cooldown_skill_3())
    }
    pub fn skill_4_cooldown(&self) -> MillisTime {
        self.character.cooldown_skill_4()
    }

    pub fn modify_cooldown(&self, cooldown: MillisTime) -> MillisTime {
        let mut new_cooldown = millis_to_u128(cooldown);

        if self.has_active_effect(&Effect::DenialOfService) {
            new_cooldown = new_cooldown * 3 / 4;
        }

        u128_to_millis(new_cooldown)
    }

    #[inline]
    pub fn add_effect(&mut self, effect: Effect, reset_countdown: bool, effect_data: EffectData) {
        if !self.effects.contains_key(&effect) {
            match self.character.name {
                Name::Muflus => {
                    if !(self.muflus_partial_immunity(&effect)) {
                        self.effects.insert(effect, effect_data);
                    }
                }
                _ => {
                    self.effects.insert(effect, effect_data);
                }
            }
        }
        // Only resets effect countdown if both effects were caused by the same attacking player
        // TODO: reset_countdown should probably be another field in the EffectData struct
        // TODO: add field "non_unique": if different sources apply the same effect on the target, target should receive multiple instances of the same effect.
        else if reset_countdown == true {
            let current_effect = self.effects.get(&effect);
            match current_effect {
                Some(current_effect) => {
                    if current_effect.caused_by == effect_data.caused_by {
                        self.effects.insert(effect, effect_data); // resets countdown
                    }
                }
                None => return (),
            }
        }
        println!("{:?}", self.effects);
    }

    pub fn remove_uma_marks(&mut self) {
        self.effects.retain(|effect, _| {
            !matches!(
                effect,
                Effect::XandaMark | Effect::XandaMarkOwner | Effect::YugenMark | Effect::ElnarMark
            )
        });
    }

    #[inline]
    pub fn speed(&self) -> u64 {
        let base_speed = self.character.base_speed;

        if self.has_active_effect(&Effect::Petrified) {
            return 0;
        }
        if self.has_active_effect(&Effect::Leaping) {
            return ((base_speed as f64) * 4.).ceil() as u64;
        }
        if self.has_active_effect(&Effect::Slowed) {
            return ((base_speed as f64) * 0.5).ceil() as u64;
        }
        if self.has_active_effect(&Effect::NeonCrashing) {
            return ((base_speed as f64) * 4.).ceil() as u64;
        }
        if self.has_active_effect(&Effect::Raged) {
            return ((base_speed as f64) * 1.5).ceil() as u64;
        }
        if self.has_active_effect(&Effect::Scherzo) {
            return ((base_speed as f64) * 0.5).ceil() as u64;
        }
        return base_speed;
    }

    fn muflus_partial_immunity(&self, effect_to_apply: &Effect) -> bool {
        effect_to_apply.is_crowd_control()
            && self.has_active_effect(&Effect::Raged)
            && Self::chance_check(0.5)
    }

    fn chance_check(chance: f64) -> bool {
        let mut rng = rand::thread_rng();
        let random: f64 = rng.gen();
        return random <= chance;
    }

    #[allow(unused_variables)]
    pub fn has_active_effect(&self, e: &Effect) -> bool {
        let effect = self.effects.get(e);
        matches!(
            effect,
            Some(EffectData {
                time_left: MillisTime {
                    high: 0_u64..=u64::MAX,
                    low: 1_u64..=u64::MAX
                },
                ..
            })
        )
    }

    ///
    /// returns whether the player can do an attack, based on:
    ///
    /// - the player's status
    /// - the character's cooldown
    /// - the character's effects
    ///
    pub fn can_attack(self: &Self, cooldown_left: MillisTime, is_basic_skill: bool) -> bool {
        if matches!(self.status, Status::DEAD) {
            return false;
        }

        if millis_to_u128(cooldown_left) > 0 {
            return false;
        }

        if self.has_active_effect(&Effect::Leaping) {
            return false;
        }

        !(self.has_active_effect(&Effect::Disarmed) && !is_basic_skill)
    }

    pub fn can_move(self: &Self) -> bool {
        if matches!(self.status, Status::DEAD) {
            return false;
        }

        if matches!(self.action, PlayerAction::ATTACKING)
            || matches!(self.action, PlayerAction::EXECUTINGSKILL1)
            || matches!(self.action, PlayerAction::EXECUTINGSKILL2)
            || matches!(self.action, PlayerAction::EXECUTINGSKILL3)
            || matches!(self.action, PlayerAction::EXECUTINGSKILL4)
            || matches!(self.action, PlayerAction::STARTINGSKILL1)
            || matches!(self.action, PlayerAction::STARTINGSKILL2)
            || matches!(self.action, PlayerAction::STARTINGSKILL3)
            || matches!(self.action, PlayerAction::STARTINGSKILL4)
        {
            return false;
        }

        !self.has_active_effect(&Effect::Leaping)
            && !self.has_active_effect(&Effect::Petrified)
            && !self.has_active_effect(&Effect::NeonCrashing)
            && !self.has_active_effect(&Effect::Paralyzed)
    }

    pub fn marks_per_player(self: &Self, attacking_player_id: u64) -> u64 {
        self.has_mark(&Effect::ElnarMark, attacking_player_id)
            + self.has_mark(&Effect::YugenMark, attacking_player_id)
            + self.has_mark(&Effect::XandaMark, attacking_player_id)
    }

    pub fn has_mark(self: &Self, e: &Effect, attacking_player_id: u64) -> u64 {
        let mark = self.effects.get(e);
        return if matches!(
            mark,
            Some(EffectData { caused_by: ap_id, .. }) if *ap_id == attacking_player_id
        ) {
            1
        } else {
            0
        };
    }

    // TODO:
    // I think cooldown duration should be measured
    // in ticks instead of seconds to ensure
    // some kind of consistency.
    pub fn update_cooldowns(&mut self, now: MillisTime) {
        // Time left of a cooldown = (start + left) - now
        // if (start) - left < now simply reset
        // the value as 0.
        self.basic_skill_cooldown_left = sub_millis(self.basic_skill_ends_at, now);

        self.skill_1_cooldown_left = sub_millis(self.skill_1_ends_at, now);

        self.skill_2_cooldown_left = sub_millis(self.skill_2_ends_at, now);

        self.skill_3_cooldown_left = sub_millis(self.skill_3_ends_at, now);

        self.skill_4_cooldown_left = sub_millis(self.skill_4_ends_at, now);
    }

    // This ill be helpful once the deathmatch mode starts its development
    pub fn _restore_player_status(&mut self, new_position: Position) {
        self.health = 100;
        self.position.x = new_position.x;
        self.position.y = new_position.y;
        self.status = Status::ALIVE;
        self.action = PlayerAction::NOTHING;
        self.aoe_position = Position::new(0, 0);
        self.effects = HashMap::new();
        self.basic_skill_cooldown_left = MillisTime { high: 0, low: 0 };
        self.skill_1_cooldown_left = MillisTime { high: 0, low: 0 };
        self.skill_2_cooldown_left = MillisTime { high: 0, low: 0 };
        self.skill_3_cooldown_left = MillisTime { high: 0, low: 0 };
        self.skill_4_cooldown_left = MillisTime { high: 0, low: 0 };
        self.basic_skill_started_at = MillisTime { high: 0, low: 0 };
        self.skill_1_started_at = MillisTime { high: 0, low: 0 };
        self.skill_2_started_at = MillisTime { high: 0, low: 0 };
        self.skill_3_started_at = MillisTime { high: 0, low: 0 };
        self.skill_4_started_at = MillisTime { high: 0, low: 0 };
    }
}

impl Position {
    pub fn new(x: usize, y: usize) -> Self {
        Self { x, y }
    }
}
