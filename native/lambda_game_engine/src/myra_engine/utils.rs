use std::cmp::Ordering;

use rustler::NifStruct;

use super::player::Position;

#[derive(Debug, Clone, Copy, NifStruct, PartialEq)]
#[module = "LambdaGameEngine.MyrraEngine.RelativePosition"]
pub struct RelativePosition {
    pub x: f32,
    pub y: f32,
}

impl RelativePosition {
    pub fn new(x: f32, y: f32) -> Self {
        Self { x, y }
    }
}

pub fn cmp_float(f1: f64, f2: f64) -> Ordering {
    if f1 < f2 {
        Ordering::Less
    } else if f1 > f2 {
        Ordering::Greater
    } else {
        Ordering::Equal
    }
}

pub fn angle_between_vectors(v1: RelativePosition, v2: RelativePosition) -> u64 {
    let angle1 = (v1.y as f32).atan2(v1.x as f32).to_degrees();
    let angle2 = (v2.y as f32).atan2(v2.x as f32).to_degrees();

    let mut angle_diff = angle1 - angle2;
    if angle_diff > 180. {
        angle_diff -= 360.;
    } else if angle_diff < -180. {
        angle_diff += 360.;
    }
    angle_diff.abs() as u64 % 360
}

pub fn hit_boxes_collide(center1: Position, center2: Position, radius1: f64, radius2: f64) -> bool {
    let squared_x = (center1.x - center2.x).pow(2) as f64;
    let squared_y = (center1.y - center2.y).pow(2) as f64;
    let centers_distance = (squared_x + squared_y).sqrt();
    let collision_distance = radius1 + radius2;
    centers_distance <= collision_distance
}
