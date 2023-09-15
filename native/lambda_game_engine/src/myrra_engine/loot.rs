use rand::{rngs::ThreadRng, Rng};
use rustler::{NifMap, NifTaggedEnum};

use super::player::Position;

#[derive(NifMap, Clone, Copy)]
pub struct Loot {
    pub id: u64,
    pub loot_type: LootType,
    pub position: Position,
    pub size: f64,
}

#[derive(NifTaggedEnum, Clone, Copy)]
pub enum LootType {
    Health(u64),
}

pub fn spawn_random_loot(id: u64, max_x: usize, max_y: usize) -> Loot {
    let rng = &mut rand::thread_rng();
    let position = Position {
        x: rng.gen_range(0..max_x),
        y: rng.gen_range(0..max_y),
    };
    match rng.gen_range(0..1) {
        _0 => random_health_loot(id, position, rng),
    }
}

fn random_health_loot(id: u64, position: Position, _rng: &mut ThreadRng) -> Loot {
    // let value: u64 = rng.gen_range(25..75);
    let value: u64 = 30;
    let loot_type = LootType::Health(value);
    Loot {
        id,
        position,
        loot_type,
        size: 50.0,
    }
}
