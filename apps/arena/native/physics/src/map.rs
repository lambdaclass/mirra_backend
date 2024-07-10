use rustler::{NifMap, NifTaggedEnum};
use serde::Deserialize;
use std::collections::HashMap;

use crate::collision_detection::sat::intersect_circle_polygon;
use crate::collision_detection::{
    circle_circle_collision, circle_polygon_collision, line_circle_collision,
    line_polygon_collision, point_circle_collision,
};
#[derive(NifMap, Clone)]
pub struct Polygon {
    pub id: u64,
    pub vertices: Vec<Position>,
}

#[derive(NifMap, Clone, Copy, Debug)]
pub struct Position {
    pub(crate) x: f32,
    pub(crate) y: f32,
}

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

impl Position {
    pub fn normalize(&mut self) {
        let length = (self.x.powi(2) + self.y.powi(2)).sqrt();
        self.x /= length;
        self.y /= length;
    }

    pub fn add(a: &Position, b: &Position) -> Position {
        Position {
            x: a.x + b.x,
            y: a.y + b.y,
        }
    }
    pub fn sub(a: &Position, b: &Position) -> Position {
        Position {
            x: a.x - b.x,
            y: a.y - b.y,
        }
    }

    pub fn mult(a: &Position, mult: f32) -> Position {
        Position {
            x: a.x * mult,
            y: a.y * mult,
        }
    }

    pub fn distance_to_position(&self, other_position: &Position) -> f32 {
        let x = self.x - other_position.x;
        let y = self.y - other_position.y;
        (x.powi(2) + y.powi(2)).sqrt()
    }
}

impl PartialEq for Position {
    fn eq(&self, other: &Position) -> bool {
        self.x == other.x && self.y == other.y
    }
}
impl Eq for Position {}

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

    pub fn new_polygon(id: u64, vertices: Vec<Position>) -> Entity {
        Entity {
            id,
            shape: Shape::Polygon,
            position: Position { x: 0.0, y: 0.0 },
            radius: 0.0,
            vertices,
            speed: 0.0,
            category: Category::Obstacle,
            direction: Direction { x: 0.0, y: 0.0 },
            is_moving: false,
            name: format!("{}{}", "Polygon ", id),
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
                (Shape::Circle, Shape::Circle) => {
                    if circle_circle_collision(self, entity) {
                        result.push(entity.id);
                    }
                }
                (Shape::Circle, Shape::Polygon) => {
                    if circle_polygon_collision(self, entity) {
                        result.push(entity.id);
                    }
                }
                (Shape::Point, Shape::Circle) => {
                    if point_circle_collision(self, entity) {
                        result.push(entity.id);
                    }
                }
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
                (Shape::Polygon, Shape::Circle) => {
                    if circle_polygon_collision(entity, self) {
                        result.push(entity.id);
                    }
                }
                _ => todo!("Collision matching not implemented"),
            }
        }

        result
    }

    pub fn move_entity(&mut self, delta_time: f32) {
        self.position = self.next_position(delta_time);
    }

    pub fn next_position(&mut self, delta_time: f32) -> Position {
        Position {
            x: self.position.x + self.direction.x * self.speed * delta_time,
            y: self.position.y + self.direction.y * self.speed * delta_time,
        }
    }

    pub fn move_entity_to_direction(&mut self, direction: Position, amount: f32) {
        let position = Position {
            x: self.position.x + direction.x * amount,
            y: self.position.y + direction.y * amount,
        };

        self.position = position;
    }

    pub fn move_to_next_valid_position_inside(&mut self, external_wall: &Entity) {
        self.position = self.find_edge_position_inside(external_wall);
    }

    pub fn move_to_next_valid_position_outside(
        &mut self,
        collided_with: Vec<&Entity>,
        obstacles: &HashMap<u64, Entity>,
        external_wall: &Entity,
    ) {
        for entity in collided_with {
            match entity.shape {
                Shape::Circle => {
                    let mut normalized_direction = Position::sub(&self.position, &entity.position);
                    normalized_direction.normalize();

                    let new_pos = Position {
                        x: entity.position.x
                            + normalized_direction.x * entity.radius
                            + normalized_direction.x * self.radius,
                        y: entity.position.y
                            + normalized_direction.y * entity.radius
                            + normalized_direction.y * self.radius,
                    };

                    self.position = new_pos;
                }
                Shape::Polygon => {
                    let (collided, direction, depth) =
                        intersect_circle_polygon(self, entity, obstacles, external_wall);

                    if collided {
                        let new_pos = Position {
                            x: self.position.x + direction.x * depth,
                            y: self.position.y + direction.y * depth,
                        };
                        self.position = new_pos;
                    }
                }
                _ => continue,
            }
        }
    }

    pub fn find_edge_position_inside(&mut self, external_wall: &Entity) -> Position {
        let x = self.position.x;
        let y = self.position.y;
        let length = (x.powf(2.) + y.powf(2.)).sqrt();
        let normalized_position = Position {
            x: self.position.x / length,
            y: self.position.y / length,
        };
        Position {
            x: external_wall.position.x
                + normalized_position.x * (external_wall.radius - self.radius),
            y: external_wall.position.y
                + normalized_position.y * (external_wall.radius - self.radius),
        }
    }

    pub fn is_inside_map(&self, external_wall: &Entity) -> bool {
        match self.shape {
            Shape::Circle => {
                let center_dist = ((external_wall.position.x - self.position.x).powi(2)
                    + (external_wall.position.y - self.position.y).powi(2))
                .sqrt();
                external_wall.radius > center_dist + self.radius
            }
            Shape::Polygon | Shape::Line => {
                for vertice in &external_wall.vertices {
                    if !is_vertice_inside_circle(
                        vertice,
                        &external_wall.position,
                        external_wall.radius,
                    ) {
                        return false;
                    }
                }
                true
            }
            Shape::Point => is_vertice_inside_circle(
                &self.position,
                &external_wall.position,
                external_wall.radius,
            ),
        }
    }
}

pub(crate) fn is_vertice_inside_circle(
    vertice: &Position,
    circle_center: &Position,
    circle_radius: f32,
) -> bool {
    let circle_center_dist =
        ((vertice.x - circle_center.x).powi(2) + (vertice.y - circle_center.y).powi(2)).sqrt();
    circle_center_dist < circle_radius
}
