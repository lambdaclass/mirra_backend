#![allow(non_snake_case)] // rustler macros generate non snake case names and dont use this allow themselves

mod collision_detection;
mod map;

use std::collections::HashMap;

use crate::map::{Category, Entity};

#[rustler::nif()]
fn add(a: i64, b: i64) -> i64 {
    a + b
}

#[rustler::nif()]
fn move_entities(entities: HashMap<u64, Entity>, external_wall: Entity) -> HashMap<u64, Entity> {
    let mut entities: HashMap<u64, Entity> = entities;

    for entity in entities.values_mut() {
        entity.move_entity();

        if entity.category == Category::Player
            && !entity.is_inside_map(&external_wall)
        {
            entity.move_to_next_valid_position(&external_wall);
        }
    }

    entities
}

#[rustler::nif()]
/// Check players inside the player_id radius
/// Return a list of the players id inside the radius Vec<player_id>
fn check_collisions(entity: Entity, entities: HashMap<u64, Entity>) -> Vec<u64> {
    let mut entity: Entity = entity;
    let ent = entities.into_values().collect();

    entity.collides_with(ent)
}

rustler::init!(
    "Elixir.Physics",
    [add, check_collisions, move_entities]
);
