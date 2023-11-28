use std::f32::consts::PI;

use rand::Rng;
use rustler::NifMap;

use crate::player::Player;

#[derive(NifMap, Clone, Copy)]
pub struct Position {
    pub x: f32,
    pub y: f32,
}

pub fn hit_boxes_collide(center1: &Position, center2: &Position, size1: u64, size2: u64) -> bool {
    let squared_x = (center1.x - center2.x).powi(2) as f64;
    let squared_y = (center1.y - center2.y).powi(2) as f64;
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
    let squared_x = (center_player.position.x - target_player.position.x).powi(2) as f64;
    let squared_y = (center_player.position.y - target_player.position.y).powi(2) as f64;
    let target_distance = (squared_x + squared_y).sqrt();

    if target_distance > (max_distance as f64) {
        return false;
    }

    let x_diff = target_player.position.x - center_player.position.x;
    let y_diff = target_player.position.y - center_player.position.y;
    let angle = y_diff.atan2(x_diff) * (180.0 / PI);
    let relative_angle = angle - center_player.direction;
    let normalized_angle = (relative_angle + 360.0) % 360.0;

    normalized_angle < (cone_angle / 2.0)
}

pub fn next_position(
    current_position: &Position,
    direction_angle: f32,
    movement_amount: f32,
    width: f32,
    height: f32,
) -> Position {
    let angle_rad = direction_angle * (PI / 180.0);
    let new_x = current_position.x + movement_amount * angle_rad.cos();
    let new_y = current_position.y + movement_amount * angle_rad.sin();

    let max_x_bound = width / 2.0;
    let min_x_bound = max_x_bound * -1.0;
    let x = new_x.min(max_x_bound).max(min_x_bound);

    let max_y_bound = height / 2.0;
    let min_y_bound = max_y_bound * -1.0;
    let y = new_y.min(max_y_bound).max(min_y_bound);

    Position { x, y }
}

pub fn collision_with_edge(center: &Position, size: u64, width: u64, height: u64) -> bool {
    let x_edge_positive = (width / 2) as f32;
    let x_position_positive = center.x + size as f32;
    if x_position_positive >= x_edge_positive {
        return true;
    }

    let x_edge_negative = width as f32 / -2.0;
    let x_position_negative = center.x - size as f32;
    if x_position_negative <= x_edge_negative {
        return true;
    }

    let y_edge_positive = (height / 2) as f32;
    let y_position_positive = center.y + size as f32;
    if y_position_positive >= y_edge_positive {
        return true;
    }

    let y_edge_negative = height as f32 / -2.0;
    let y_position_negative = center.y - size as f32;
    if y_position_negative <= y_edge_negative {
        return true;
    }

    false
}

pub fn random_position(width: u64, height: u64) -> Position {
    let rng = &mut rand::thread_rng();
    let bound_x = (width / 2) as f32;
    let bound_y = (height / 2) as f32;

    Position {
        x: rng.gen_range(-bound_x..bound_x),
        y: rng.gen_range(-bound_y..bound_y),
    }
}

pub fn angle_between_positions(center: &Position, target: &Position) -> f32 {
    let x_diff = target.x - center.x;
    let y_diff = target.y - center.y;
    let angle = y_diff.atan2(x_diff) * (180.0 / PI);
    (angle + 360.0) % 360.0
}

pub fn distance_to_center(player: &Player, center: &Position) -> f32 {
    let distance_squared =
        (player.position.x - center.x).powi(2) + (player.position.y - center.y).powi(2);
    distance_squared.sqrt()
}
