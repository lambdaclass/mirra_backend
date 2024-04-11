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
fn move_entities(
    entities: HashMap<u64, Entity>,
    ticks_to_move: f32,
    external_wall: Entity,
    obstacles: HashMap<u64, Entity>,
) -> HashMap<u64, Entity> {
    let mut entities: HashMap<u64, Entity> = entities;

    for entity in entities.values_mut() {
        if entity.is_moving {
            entity.move_entity(ticks_to_move);

            if entity.category == Category::Player && !entity.is_inside_map(&external_wall) {
                entity.move_to_next_valid_position_inside(&external_wall);
            }

            let collides_with = entity.collides_with(obstacles.clone().into_values().collect());

            if entity.category == Category::Player && !collides_with.is_empty() {
                let collided_with: Vec<&Entity> = collides_with
                    .iter()
                    .map(|id| obstacles.get(id).unwrap())
                    .collect();
                entity.move_to_next_valid_position_outside(collided_with);
            }
        }
    }

    entities
}

#[rustler::nif()]
fn move_entity(
    entity: Entity,
    ticks_to_move: f32,
    external_wall: Entity,
    obstacles: HashMap<u64, Entity>,
) -> Entity {
    let mut entity: Entity = entity;
    if entity.is_moving {
        entity.move_entity(ticks_to_move);

        if entity.category == Category::Player && !entity.is_inside_map(&external_wall) {
            entity.move_to_next_valid_position_inside(&external_wall);
        }

        let collides_with = entity.collides_with(obstacles.clone().into_values().collect());

        if entity.category == Category::Player && !collides_with.is_empty() {
            let collided_with: Vec<&Entity> = collides_with
                .iter()
                .map(|id| obstacles.get(id).unwrap())
                .collect();
            entity.move_to_next_valid_position_outside(collided_with);
        }
    }

    entity
}

#[rustler::nif()]
fn move_entity_to_position(
    entity: Entity,
    new_position: Position,
    external_wall: Entity,
    obstacles: HashMap<u64, Entity>,
) -> Entity {
    let mut entity: Entity = entity;
    entity.position = new_position;

    if entity.category == Category::Player && !entity.is_inside_map(&external_wall) {
        entity.move_to_next_valid_position_inside(&external_wall);
    }

    let collides_with = entity.collides_with(obstacles.clone().into_values().collect());

    if entity.category == Category::Player && !collides_with.is_empty() {
        let collided_with: Vec<&Entity> = collides_with
            .iter()
            .map(|id| obstacles.get(id).unwrap())
            .collect();
        entity.move_to_next_valid_position_outside(collided_with);
    }
    entity
}

#[rustler::nif()]
fn move_entity_to_direction(
    entity: Entity,
    direction: Position,
    amount: f32,
    external_wall: Entity,
    obstacles: HashMap<u64, Entity>,
) -> Entity {
    let mut entity: Entity = entity;
    entity.move_entity_to_direction(direction, amount);
    if entity.category == Category::Player && !entity.is_inside_map(&external_wall) {
        entity.move_to_next_valid_position_inside(&external_wall);
    }

    let collides_with = entity.collides_with(obstacles.clone().into_values().collect());

    if entity.category == Category::Player && !collides_with.is_empty() {
        let collided_with: Vec<&Entity> = collides_with
            .iter()
            .map(|id| obstacles.get(id).unwrap())
            .collect();
        entity.move_to_next_valid_position_outside(collided_with);
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
    let v1_angle_x = (direction_angle + angle.to_radians()).cos();
    let v1_angle_y = (direction_angle + angle.to_radians()).sin();

    let v2_angle_x = (direction_angle - angle.to_radians()).cos();
    let v2_angle_y = (direction_angle - angle.to_radians()).sin();

    let len_result = (v2_angle_x.powi(2) + v2_angle_y.powi(2)).sqrt();

    let vertix_1 = Position {
        x: starting_point.x + v1_angle_x / len_result * range,
        y: starting_point.y + v1_angle_y / len_result * range,
    };
    let vertix_2 = Position {
        x: starting_point.x + v2_angle_x / len_result * range,
        y: starting_point.y + v2_angle_y / len_result * range,
    };

    vec![starting_point, vertix_1, vertix_2]
}

#[rustler::nif()]
fn get_direction_from_positions(position_a: Position, position_b: Position) -> Direction {
    direction_from_positions(position_a, position_b)
}

#[rustler::nif()]
fn calculate_speed(position_a: Position, position_b: Position, duration: u64) -> f32 {
    let len = distance_between_positions(position_a, position_b);
    len / duration as f32
}

#[rustler::nif()]
fn nearest_entity_direction(entity: Entity, entities: HashMap<u64, Entity>) -> Direction {
    let mut max_distance = 2000.0;
    let mut direction = Direction {
        x: entity.direction.x,
        y: entity.direction.y,
    };

    for other_entity in entities.values() {
        if entity.id != other_entity.id {
            let distance = distance_between_positions(entity.position, other_entity.position);
            if distance < max_distance {
                max_distance = distance;
                direction = direction_from_positions(entity.position, other_entity.position);
            }
        }
    }

    direction
}

fn distance_between_positions(entity_a_postion: Position, entity_b_postion: Position) -> f32 {
    let x = entity_b_postion.x - entity_a_postion.x;
    let y = entity_b_postion.y - entity_a_postion.y;
    (x.powi(2) + y.powi(2)).sqrt()
}

// This is a wrapper function to be able to call it from the rustler nif
fn direction_from_positions(position_a: Position, position_b: Position) -> Direction {
    let x = position_b.x - position_a.x;
    let y = position_b.y - position_a.y;
    let len = (x.powi(2) + y.powi(2)).sqrt();
    Direction {
        x: x / len,
        y: y / len,
    }
}

rustler::init!(
    "Elixir.Physics",
    [
        add,
        check_collisions,
        move_entities,
        move_entity,
        move_entity_to_direction,
        add_angle_to_direction,
        calculate_triangle_vertices,
        get_direction_from_positions,
        calculate_speed,
        nearest_entity_direction,
        move_entity_to_position
    ]
);
