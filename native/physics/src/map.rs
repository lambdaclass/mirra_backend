use rustler::{NifMap, NifTaggedEnum};
use serde::Deserialize;

use crate::collision_detection::{
    circle_circle_collision, circle_polygon_collision, line_circle_collision,
    point_circle_collision,
};

#[derive(NifMap, Clone)]
pub struct Polygon {
    pub id: u64,
    pub vertices: Vec<Position>,
}

#[derive(NifMap, Clone, Copy, Debug)]
pub struct Position {
    pub(crate) x: f64,
    pub(crate) y: f64,
}

#[derive(NifMap, Clone, Copy, Debug)]
pub struct Direction {
    pub(crate) x: f64,
    pub(crate) y: f64,
}

#[derive(NifMap, Clone, Debug)]
pub struct Entity {
    pub id: u64,
    pub shape: Shape,
    pub position: Position,
    pub radius: f64,
    pub vertices: Vec<Position>,
    pub speed: f64,
    pub category: Category,
    pub direction: Direction,
}

#[derive(Deserialize, NifTaggedEnum, Clone, PartialEq, Debug)]
pub enum Shape {
    Circle,
    Polygon,
    Point,
    Line,
}

#[derive(Deserialize, NifTaggedEnum, Clone, PartialEq, Debug)]
pub enum Category {
    Player,
    Projectile,
    Obstacle,
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
        }
    }

    pub fn new_circle(
        id: u64,
        position: Position,
        radius: f64,
        speed: f64,
        category: Category,
    ) -> Entity {
        Entity {
            id,
            shape: Shape::Circle,
            position,
            radius,
            vertices: Vec::new(),
            speed,
            category,
            direction: Direction { x: 0.0, y: 0.0 },
        }
    }

    pub fn new_polygon(id: u64, vertices: Vec<Position>, category: Category) -> Entity {
        Entity {
            id,
            shape: Shape::Polygon,
            position: Position { x: 0.0, y: 0.0 },
            radius: 0.0,
            vertices,
            speed: 0.0,
            category,
            direction: Direction { x: 0.0, y: 0.0 },
        }
    }

    pub fn collides_with(&mut self, entities: &Vec<Entity>) -> Vec<Entity> {
        let mut result = Vec::new();

        for entity in entities {
            if entity.id == self.id {
                continue;
            }

            match entity.shape {
                Shape::Circle => {
                    if circle_circle_collision(self, entity) {
                        result.push(entity.clone());
                    }
                }
                Shape::Polygon => {
                    if circle_polygon_collision(self, entity) {
                        result.push(entity.clone());
                    }
                }
                Shape::Point => {
                    if point_circle_collision(self, entity) {
                        result.push(entity.clone());
                    }
                }
                Shape::Line => {
                    if line_circle_collision(self, entity) {
                        result.push(entity.clone());
                    }
                }
            }
        }

        result
    }

    pub fn move_entity(&mut self) {
        self.position = self.next_position();
    }
    pub fn revert_move_entity(&mut self) {
        self.position = self.revert_position();
    }

    pub fn next_position(&mut self) -> Position {
        Position {
            x: self.position.x + self.direction.x * self.speed,
            y: self.position.y + self.direction.y * self.speed,
        }
    }

    pub fn revert_position(&mut self) -> Position {
        Position {
            x: self.position.x - self.direction.x * self.speed,
            y: self.position.y - self.direction.y * self.speed,
        }
    }

    pub fn set_direction(&mut self, x: f64, y: f64) {
        self.direction.x = x;
        self.direction.y = y;
    }
}
