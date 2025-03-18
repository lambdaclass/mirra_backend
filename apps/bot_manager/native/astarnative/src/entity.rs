use super::Position;
use rustler::{NifMap, NifTaggedEnum};
use serde::Deserialize;

use crate::collision_detection::{
    line_circle_collision, line_polygon_collision,
};

#[derive(NifMap, Clone, Copy)]
pub struct Direction {
    pub(crate) x: f32,
    pub(crate) y: f32,
}

#[derive(NifMap, Clone)]
pub struct Entity {
    pub id: u64,
    pub shape: Shape,
    pub position: Position,
    pub radius: f32,
    pub vertices: Vec<Position>,
    pub speed: f32,
    pub category: Category,
    pub direction: Direction,
    pub is_moving: bool,
    pub name: String,
}

#[derive(Deserialize, NifTaggedEnum, Clone, PartialEq)]
pub enum Shape {
    Circle,
    Polygon,
    Point,
    Line,
}

#[derive(Deserialize, NifTaggedEnum, Clone, PartialEq)]
pub enum Category {
    Player,
    Projectile,
    Obstacle,
    PowerUp,
    Pool,
    Item,
    Bush,
    Crate,
    Trap,
}

impl Entity {
    pub fn new_point(id: u64, position: Position) -> Entity {
        Entity {
            id,
            shape: Shape::Point,
            position,
            radius: 0.0,
            vertices: Vec::new(),
            speed: 0.0,
            category: Category::Obstacle,
            direction: Direction { x: 0.0, y: 0.0 },
            is_moving: false,
            name: format!("{}{}", "Point ", id),
        }
    }

    pub fn new_line(id: u64, vertices: Vec<Position>) -> Entity {
        Entity {
            id,
            shape: Shape::Line,
            position: Position { x: 0.0, y: 0.0 },
            radius: 0.0,
            vertices,
            speed: 0.0,
            category: Category::Obstacle,
            direction: Direction { x: 0.0, y: 0.0 },
            is_moving: false,
            name: format!("{}{}", "Line ", id),
        }
    }

    pub fn collides_with(&mut self, entities: &Vec<Entity>) -> Vec<u64> {
        let mut result = Vec::new();

        for entity in entities {
            if entity.id == self.id {
                continue;
            }

            let self_shape = self.shape.clone();
            let entity_shape = entity.shape.clone();

            match (self_shape, entity_shape) {
                (Shape::Line, Shape::Circle) => {
                    if line_circle_collision(self, entity) {
                        result.push(entity.id);
                    }
                }

                (Shape::Line, Shape::Polygon) => {
                    if line_polygon_collision(self, entity) {
                        result.push(entity.id);
                    }
                }
                _ => todo!("Collision matching not implemented"),
            }
        }

        result
    }
}
