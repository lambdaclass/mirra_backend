use rustler::{NifMap, NifTaggedEnum};
use serde::Deserialize;

use crate::collision_detection::{
    circle_circle_collision, circle_polygon_collision, get_closest_point_between_line_and_circle,
    line_circle_collision, point_circle_collision,
};

#[derive(NifMap, Clone)]
pub struct Polygon {
    pub id: u64,
    pub vertices: Vec<Position>,
}

#[derive(NifMap, Clone, Copy)]
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
    Item,
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
        }
    }

    pub fn collides_with(&mut self, entities: Vec<Entity>) -> Vec<u64> {
        let mut result = Vec::new();

        for entity in entities {
            if entity.id == self.id {
                continue;
            }

            let self_shape = self.shape.clone();
            let entity_shape = entity.shape.clone();

            match (self_shape, entity_shape) {
                (Shape::Circle, Shape::Circle) => {
                    if circle_circle_collision(self, &entity) {
                        result.push(entity.id);
                    }
                }
                (Shape::Circle, Shape::Polygon) => {
                    if circle_polygon_collision(self, &entity) {
                        result.push(entity.id);
                    }
                }
                (Shape::Point, Shape::Circle) => {
                    if point_circle_collision(self, &entity) {
                        result.push(entity.id);
                    }
                }
                (Shape::Line, Shape::Circle) => {
                    if line_circle_collision(self, &entity) {
                        result.push(entity.id);
                    }
                }
                (Shape::Polygon, Shape::Circle) => {
                    if circle_polygon_collision(&entity, self) {
                        result.push(entity.id);
                    }
                }
                _ => todo!("Collision matching not implemented"),
            }
        }

        result
    }

    pub fn move_entity(&mut self, ticks_to_move: f32) {
        self.position = self.next_position(ticks_to_move);
    }

    pub fn next_position(&mut self, ticks_to_move: f32) -> Position {
        Position {
            x: self.position.x + self.direction.x * self.speed * ticks_to_move,
            y: self.position.y + self.direction.y * self.speed * ticks_to_move,
        }
    }

    pub fn move_to_next_valid_position_inside(&mut self, external_wall: &Entity) {
        self.position = self.find_edge_position_inside(external_wall);
    }

    pub fn move_to_next_valid_position_outside(&mut self, external_wall: &Entity) {
        self.position = self.find_edge_position_outside(external_wall);
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

    pub fn find_edge_position_outside(&mut self, entity: &Entity) -> Position {
        match entity.shape {
            Shape::Circle => {
                let x = self.position.x - entity.position.x;
                let y = self.position.y - entity.position.y;
                let length = (x.powf(2.) + y.powf(2.)).sqrt();
                let normalized_direction = Position {
                    x: x / length,
                    y: y / length,
                };
                Position {
                    x: entity.position.x
                        + normalized_direction.x * entity.radius
                        + normalized_direction.x * self.radius,
                    y: entity.position.y
                        + normalized_direction.y * entity.radius
                        + normalized_direction.y * self.radius,
                }
            }
            Shape::Polygon => {
                let mut collition_points: Vec<Entity> = vec![];
                for current in 0..entity.vertices.len() {
                    let mut next = current + 1;
                    if next == entity.vertices.len() {
                        next = 0
                    };

                    let current_line =
                        Entity::new_line(0, vec![entity.vertices[current], entity.vertices[next]]);
                    for collided_point in
                        get_closest_point_between_line_and_circle(&current_line, &self)
                    {
                        let x = self.position.x - collided_point.position.x;
                        let y = self.position.y - collided_point.position.y;
                        let closest_point_length = (x.powf(2.) + y.powf(2.)).sqrt();

                        if closest_point_length < self.radius {
                            collition_points.push(collided_point);
                        }
                    }
                }

                let mut base_position = self.position;
                collition_points
                    .dedup_by(|a, b| a.position.x == b.position.x && a.position.y == b.position.y);

                for collided_point in collition_points {
                    println!(
                        "aber point x: {:?} y: {:?}",
                        collided_point.position.x, collided_point.position.y
                    );
                    let x = base_position.x - collided_point.position.x;
                    let y = base_position.y - collided_point.position.y;
                    let length = (x.powf(2.) + y.powf(2.)).sqrt();
                    let normalized_direction = Position {
                        x: x / length,
                        y: y / length,
                    };
                    base_position.x =
                        collided_point.position.x + normalized_direction.x * self.radius;
                    base_position.y =
                        collided_point.position.y + normalized_direction.y * self.radius;
                }
                base_position
            }
            _ => self.position,
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
