#![allow(non_snake_case)] // rustler macros generate non snake case names and dont use this allow themselves

mod collision_detection;
mod map;

use crate::collision_detection::ear_clipping;
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

            move_entity_to_closest_available_position(entity, &external_wall, &obstacles);
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
        move_entity_to_closest_available_position(&mut entity, &external_wall, &obstacles);
    }

    entity
}

#[rustler::nif()]
fn get_closest_available_position(
    new_position: Position,
    entity: Entity,
    external_wall: Entity,
    obstacles: HashMap<u64, Entity>,
) -> Position {
    let mut entity: Entity = entity;
    entity.position = new_position;

    move_entity_to_closest_available_position(&mut entity, &external_wall, &obstacles);
    entity.position
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
    move_entity_to_closest_available_position(&mut entity, &external_wall, &obstacles);

    entity
}

#[rustler::nif()]
/// Check players inside the player_id radius
/// Return a list of the players id inside the radius Vec<player_id>
fn check_collisions(entity: Entity, entities: HashMap<u64, Entity>) -> Vec<u64> {
    let mut entity: Entity = entity;
    let ent = entities.into_values().collect();

    entity.collides_with(&ent)
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
fn calculate_duration(position_a: Position, position_b: Position, speed: f32) -> u64 {
    let len = distance_between_positions(position_a, position_b);
    (len / speed) as u64
}

#[rustler::nif()]
fn nearest_entity_position_in_range(
    entity: Entity,
    entities: HashMap<u64, Entity>,
    range: i64,
) -> (bool, Position) {
    let mut max_distance = range as f32;
    let mut position = Position {
        x: entity.direction.x,
        y: entity.direction.y,
    };
    let mut use_autoaim: bool = false;

    for other_entity in entities.values() {
        if entity.id != other_entity.id {
            let distance = distance_between_positions(entity.position, other_entity.position);
            if distance < max_distance {
                max_distance = distance;
                let difference_between_positions =
                    Position::sub(&other_entity.position, &entity.position);
                position = Position {
                    x: difference_between_positions.x,
                    y: difference_between_positions.y,
                };
                use_autoaim = true;
            }
        }
    }

    (use_autoaim, position)
}
#[rustler::nif()]
fn distance_between_entities(entity_a: Entity, entity_b: Entity) -> f32 {
    distance_between_positions(entity_a.position, entity_b.position)
        - entity_a.radius
        - entity_b.radius
}

#[rustler::nif()]
fn maybe_triangulate_concave_entities(obstacles: Vec<Entity>) -> Vec<Entity> {
    let mut result = vec![];
    for obstacle in obstacles {
        let mut triangulated_polygons = ear_clipping::maybe_triangulate_polygon(obstacle);
        result.append(&mut triangulated_polygons);
    }
    result
}

fn move_entity_to_closest_available_position(
    entity: &mut Entity,
    external_wall: &Entity,
    obstacles: &HashMap<u64, Entity>,
) {
    if entity.category == Category::Player && !entity.is_inside_map(external_wall) {
        entity.move_to_next_valid_position_inside(external_wall);
    }

    let collides_with = entity.collides_with(&obstacles.clone().into_values().collect());

    if entity.category == Category::Player && !collides_with.is_empty() {
        let collided_with: Vec<&Entity> = collides_with
            .iter()
            .map(|id| obstacles.get(id).unwrap())
            .collect();
        entity.move_to_next_valid_position_outside(collided_with, obstacles, external_wall);
    }
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
    if len == 0.0 {
        return Direction { x: 0.0, y: 0.0 };
    }
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
        calculate_duration,
        distance_between_entities,
        nearest_entity_position_in_range,
        get_closest_available_position,
        maybe_triangulate_concave_entities
    ]
);
