use std::collections::HashMap;

use rustler::NifMap;
use rustler::NifTaggedEnum;

use crate::map::Position;
use crate::character::CharacterConfig;

#[derive(NifMap)]
pub struct Player {
    id: u64,
    character: CharacterConfig,
    status: PlayerStatus,
    kill_count: u64,
    death_count: u64,
    position: Position,
    direction: u64,
    actions: Vec<PlayerAction>,
    health: u64,
    cooldowns: HashMap<String, u64>,
    size: u64,
    damage: u64,
}

#[derive(NifTaggedEnum, Clone)]
pub enum PlayerStatus {
  Alive, Death
}

#[derive(NifTaggedEnum, Clone)]
pub enum PlayerAction {
  Nothing,
  Attacking,
  Attackingaoe,
  Moving,
  StartingSkill(String),
  ExecutingSkill(String),
}
