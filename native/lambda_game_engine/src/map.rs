use std::f32::consts::PI;

use rustler::NifMap;

#[derive(NifMap, Clone)]
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

pub fn next_position(
    current_position: &Position,
    direction_angle: f32,
    movement_amount: f32,
    width: f32,
    height: f32,
) -> Position {
    let angle_rad = direction_angle * (PI / 180.0);
    let new_x = (current_position.x as f32) + movement_amount * angle_rad.cos();
    let new_y = (current_position.y as f32) + movement_amount * angle_rad.sin();

    let max_x_bound = width / 2.0;
    let min_x_bound = max_x_bound * -1.0;
    let x = new_x.min(max_x_bound).max(min_x_bound);

    let max_y_bound = height / 2.0;
    let min_y_bound = max_y_bound * -1.0;
    let y = new_y.min(max_y_bound).max(min_y_bound);

    Position {
        x: x as i64,
        y: y as i64,
    }
}

pub fn collision_with_edge(center: &Position, size: u64, width: u64, height: u64) -> bool {
    let x_edge_positive = (width / 2) as i64;
    let x_position_positive = center.x + size as i64;
    if x_position_positive >= x_edge_positive {
        return true;
    }

    let x_edge_negative = width as i64 / -2;
    let x_position_negative = center.x - size as i64;
    if x_position_negative <= x_edge_negative {
        return true;
    }

    let y_edge_positive = (height / 2) as i64;
    let y_position_positive = center.y + size as i64;
    if y_position_positive >= y_edge_positive {
        return true;
    }

    let y_edge_negative = height as i64 / -2;
    let y_position_negative = center.y - size as i64;
    if y_position_negative <= y_edge_negative {
        return true;
    }

    false
}
