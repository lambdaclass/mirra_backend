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
