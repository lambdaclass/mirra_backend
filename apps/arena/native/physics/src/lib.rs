#![allow(non_snake_case)] // rustler macros generate non snake case names and dont use this allow themselves

mod collision_detection;
mod map;

use crate::map::{Category, Direction, Entity, Position};
use std::collections::HashMap;

#[rustler::nif()]
fn add(a: i64, b: i64) -> i64 {
    a + b
}

#[rustler::nif()]
fn move_entities(entities: HashMap<u64, Entity>, external_wall: Entity) -> HashMap<u64, Entity> {
    let mut entities: HashMap<u64, Entity> = entities;

    for entity in entities.values_mut() {
        if entity.is_moving {
            entity.move_entity();

            if entity.category == Category::Player && !entity.is_inside_map(&external_wall) {
                entity.move_to_next_valid_position(&external_wall);
            }
        }
    }

    entities
}

#[rustler::nif()]
fn move_entity(entity: Entity, external_wall: Entity) -> Entity {
    let mut entity: Entity = entity;
    if entity.is_moving {
        entity.move_entity();

        if entity.category == Category::Player && !entity.is_inside_map(&external_wall) {
            entity.move_to_next_valid_position(&external_wall);
        }
    }

    entity
}

#[rustler::nif()]
/// Check players inside the player_id radius
/// Return a list of the players id inside the radius Vec<player_id>
fn check_collisions(entity: Entity, entities: HashMap<u64, Entity>) -> Vec<u64> {
    let mut entity: Entity = entity;
    let ent = entities.into_values().collect();

    entity.collides_with(ent)
}

#[rustler::nif()]
fn add_angle_to_direction(direction: Direction, angle: f32) -> Direction {
    let direction_angle = direction.y.atan2(direction.x);
    let angle_x = (angle.to_radians() + direction_angle).cos();
    let angle_y = (angle.to_radians() + direction_angle).sin();
    let result_x = direction.x + angle_x;
    let result_y = direction.y + angle_y;
    let len_result = (result_x.powi(2) + result_y.powi(2)).sqrt();
    Direction {
        x: result_x / len_result,
        y: result_y / len_result,
    }
}

#[rustler::nif()]
fn calculate_triangle_vertices(
    starting_point: Position,
    direction: Direction,
    range: f32,
    angle: f32,
) -> Vec<Position> {
    let direction_angle = direction.y.atan2(direction.x);
    let angle_x = (angle.to_radians() + direction_angle).cos();
    let angle_y = (angle.to_radians() + direction_angle).sin();
    let result_x = direction.x + angle_x;
    let result_y = direction.y + angle_y;
    let len_result = (result_x.powi(2) + result_y.powi(2)).sqrt();
    let direction = Direction {
        x: result_x / len_result,
        y: result_y / len_result,
    };

    let vertix_1 = Position {
        x: starting_point.x + direction.x * range,
        y: starting_point.y + direction.y * range,
    };
    let vertix_2 = Position {
        x: starting_point.x + direction.x * range,
        y: starting_point.y - direction.y * range,
    };

    vec![starting_point, vertix_1, vertix_2]
}

#[rustler::nif()]
fn get_direction_from_positions(position_a: Position, position_b: Position) -> Direction {
    let x = position_b.x - position_a.x;
    let y = position_b.y - position_a.y;
    let len = (x.powi(2) + y.powi(2)).sqrt();
    Direction {
        x: x / len,
        y: y / len,
    }
}

#[rustler::nif()]
fn calculate_speed(position_a: Position, position_b: Position, duration: u64) -> f32 {
    let x = position_b.x - position_a.x;
    let y = position_b.y - position_a.y;
    let len = (x.powi(2) + y.powi(2)).sqrt();
    len / duration as f32
}

rustler::init!(
    "Elixir.Physics",
    [
        add,
        check_collisions,
        move_entities,
        move_entity,
        add_angle_to_direction,
        calculate_triangle_vertices,
        get_direction_from_positions,
        calculate_speed
    ]
);
