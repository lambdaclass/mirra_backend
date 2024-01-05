use rustler::NifMap;

use crate::player::Position;

#[derive(NifMap, Clone)]
pub struct Polygon {
    pub id: u64,
    pub vertices: Vec<Position>,
}

impl Polygon {
    pub fn new(id: u64, vertices: Vec<Position>) -> Polygon {
        Polygon { id, vertices }
    }

    pub fn exist_collision(&mut self, position: &Position) -> bool {
        let mut collision: bool = false;
        for i in 0..self.vertices.len(){
            let mut next = i + 1;
            if next == self.vertices.len() {
                next = 0;
            }
            let current_vertex = &self.vertices[i];
            let next_vertex = &self.vertices[next];

            if (current_vertex.y > position.y) != (next_vertex.y > position.y) {
                if position.x < (next_vertex.x - current_vertex.x) * (position.y - current_vertex.y) / (next_vertex.y - current_vertex.y) + current_vertex.x {
                    collision = !collision;
                }
            }
        }
        collision
    }
}
