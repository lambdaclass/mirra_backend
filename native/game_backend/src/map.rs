use std::f32::consts::PI;

use rand::Rng;
use rustler::NifMap;
use serde::Deserialize;

use crate::player::Player;

#[derive(NifMap, Clone, Deserialize, Copy)]
pub struct Position {
    pub x: i64,
    pub y: i64,
}

pub fn hit_boxes_collide(center1: &Position, center2: &Position, size1: u64, size2: u64) -> bool {
    let squared_x = (center1.x - center2.x).pow(2) as f64;
    let squared_y = (center1.y - center2.y).pow(2) as f64;
    let centers_distance = (squared_x + squared_y).sqrt();
    let collision_distance = (size1 + size2) as f64;
    centers_distance <= collision_distance
}

pub fn in_cone_angle_range(
    center_player: &Player,
    target_player: &Player,
    max_distance: u64,
    cone_angle: f32,
) -> bool {
    // TODO: Take into consideration `size` attribute of Player
    let squared_x = (center_player.position.x - target_player.position.x).pow(2) as f64;
    let squared_y = (center_player.position.y - target_player.position.y).pow(2) as f64;
    let target_distance = (squared_x + squared_y).sqrt();

    if target_distance > (max_distance as f64) {
        return false;
    } else if target_distance <= ((center_player.size * 3) as f64) {
        return true;
    }

    let x_diff = (target_player.position.x - center_player.position.x) as f32;
    let y_diff = (target_player.position.y - center_player.position.y) as f32;
    let angle = y_diff.atan2(x_diff) * (180.0 / PI);
    let relative_angle = angle - center_player.direction;
    let normalized_angle = (relative_angle + 360.0) % 360.0;

    360.0 - (cone_angle / 2.0) < normalized_angle || normalized_angle < (cone_angle / 2.0)
}

pub fn next_position(
    current_position: &Position,
    direction_angle: f32,
    movement_amount: f32,
    inner_radius: f32,
    outer_radius: f32,
) -> Position {
    let angle_rad = direction_angle * (PI / 180.0);
    let new_x = movement_amount.mul_add(angle_rad.cos(), current_position.x as f32);
    let new_y = movement_amount.mul_add(angle_rad.sin(), current_position.y as f32);

    let center = Position { x: 0, y: 0 };

    let new_position = Position {
        x: new_x as i64,
        y: new_y as i64,
    };

    let distance_between_positions = distance_between_positions(&new_position, &center);

    if distance_between_positions >= outer_radius {
        let angle = angle_between_positions(&center, &new_position) * (PI / 180.0);

        Position {
            x: (outer_radius * angle.cos()) as i64,
            y: (outer_radius * angle.sin()) as i64,
        }
    } else if distance_between_positions <= inner_radius {
        let angle = angle_between_positions(&center, &new_position) * (PI / 180.0);

        Position {
            x: (inner_radius * angle.cos()) as i64,
            y: (inner_radius * angle.sin()) as i64,
        }
    } else {
        new_position
    }
}

pub fn collision_with_edge(
    pos: &Position,
    size: u64,
    outer_radius: u64,
    inner_radius: u64,
) -> bool {
    let num = ((pos.x.pow(2) + pos.y.pow(2)) as f64).sqrt();

    if num >= (outer_radius - size) as f64 || num <= (inner_radius + size) as f64 {
        return true;
    }
    false
}

pub fn random_position(outer_radius: u64, inner_radius: u64) -> Position {
    let rng = &mut rand::thread_rng();

    let random_radius = (rng.gen_range(inner_radius..outer_radius.pow(2)) as f32).sqrt();
    let angle = rng.gen_range(0.0..(2.0 * PI));

    Position {
        x: (random_radius * angle.cos()) as i64,
        y: (random_radius * angle.sin()) as i64,
    }
}

pub fn angle_between_positions(center: &Position, target: &Position) -> f32 {
    let x_diff = (target.x - center.x) as f32;
    let y_diff = (target.y - center.y) as f32;
    let angle = y_diff.atan2(x_diff) * (180.0 / PI);
    (angle + 360.0) % 360.0
}

pub fn distance_between_positions(position_1: &Position, position_2: &Position) -> f32 {
    let distance_squared =
        (position_1.x - position_2.x).pow(2) + (position_1.y - position_2.y).pow(2);
    (distance_squared as f32).sqrt()
}
