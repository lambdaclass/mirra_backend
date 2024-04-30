use std::collections::HashMap;
use std::mem::swap;

use crate::map::{Entity, Position};
/*
    Collision detection using the [SAT theorem](https://dyn4j.org/2010/01/sat/)
    To determine if a pair of shapes are colliding we'll try to draw a line from an axis where the entities
    are not overlaped, if we found at least one axis that meet this we can ensure that the entities are not
    overlaping

    DISCLAIMER: this algorithm works for collisions with polygons that are CONVEX ONLY which means
    that ALL of his internal angles has less than 180° degrees, if we would have a CONCAVE polygon this
    should be built differently. The usage of various convex polygons can be a solution.

*/

// Handle the intesection between a circle and a polygon, the return value is a tuple of 3 elements:
// 1: bool = true if the entities are colliding
// 2: Position = nomalized line of collision
// 3: f32 = the minimum amount of overlap between the shapes that would solve the collision
pub(crate) fn intersect_circle_polygon(
    circle: &mut Entity,
    polygon: &Entity,
    obstacles: &HashMap<u64, Entity>,
) -> (bool, Position, f32) {
    // The normal will be the vector in which the polygons should move to stop colliding
    let mut normal = Position { x: 0.0, y: 0.0 };
    // The depth is the amount of overlapping between both entities
    let mut result_depth: f32 = f32::MAX;

    let mut axis: Position;

    // Check normal and depth for polygon
    for current_vertex_index in 0..polygon.vertices.len() {
        let mut next_vertex_index = current_vertex_index + 1;
        if next_vertex_index == polygon.vertices.len() {
            next_vertex_index = 0
        };
        let current_vertex = polygon.vertices[current_vertex_index];
        let next_vertex = polygon.vertices[next_vertex_index];

        let current_line = Position::sub(current_vertex, next_vertex);
        // the axis will be the perpendicular line drawn from the current line of the polygon
        axis = Position {
            x: -current_line.y,
            y: current_line.x,
        };

        // FIXME normalizing on this loop may be bad
        axis.normalize();
        if invalid_axis(
            axis,
            circle,
            &polygon,
            &current_vertex,
            &next_vertex,
            obstacles,
        ) {
            continue;
        }
        let (min_polygon_cast_point, max_polygon_cast_point) =
            project_vertices(&polygon.vertices, axis);
        let (min_circle_cast_point, max_circle_cast_point) = project_circle(circle, axis);

        // If there's a gap between the polygon it means they do not collide and we can safely return false
        if min_polygon_cast_point >= max_circle_cast_point
            || min_circle_cast_point >= max_polygon_cast_point
        {
            return (false, normal, result_depth);
        }

        let circle_overlap_depth = max_circle_cast_point - min_polygon_cast_point;

        let polygon_overlap_depth = max_polygon_cast_point - min_circle_cast_point;

        let min_depth = f32::min(circle_overlap_depth, polygon_overlap_depth);

        if min_depth < result_depth {
            // If we hit the polygon from the right or top we need to turn around the direction
            if polygon_overlap_depth > circle_overlap_depth {
                normal = Position {
                    x: -axis.x,
                    y: -axis.y,
                };
            } else {
                normal = axis;
            }
            result_depth = min_depth;
        }
    }

    // Check normal and depth for center
    let closest_vertex = find_closest_vertex(&circle.position, &polygon.vertices);
    axis = Position::sub(closest_vertex, circle.position);
    axis.normalize();

    let (min_polygon_cast_point, max_polygon_cast_point) =
        project_vertices(&polygon.vertices, axis);
    let (min_circle_cast_point, max_circle_cast_point) = project_circle(circle, axis);

    // If there's a gap between the polygon it means they do not collide and we can safely return false
    if min_polygon_cast_point >= max_circle_cast_point
        || min_circle_cast_point >= max_polygon_cast_point
    {
        return (false, normal, result_depth);
    }

    let circle_overlap_depth = max_circle_cast_point - min_polygon_cast_point;

    let polygon_overlap_depth = max_polygon_cast_point - min_circle_cast_point;

    let axis_depth = f32::min(circle_overlap_depth, polygon_overlap_depth);

    if axis_depth < result_depth {
        // If we hit the polygon from the right or top we need to turn around the direction
        if polygon_overlap_depth > circle_overlap_depth {
            normal = Position {
                x: -axis.x,
                y: -axis.y,
            };
        } else {
            normal = axis;
        }
        result_depth = axis_depth;
    }

    (true, normal, result_depth)
}

// Uncomment this if we need a polygon-polygon collision detection

// Handle the intesection between two polygons, the return value is a tuple of 3 elements
// a: bool = true if the entities are colliding
// b: Position = nomalized line of collision
// c: f32 = the amount of overlap between the shapes
// pub(crate) fn intersect_polygon_polygon(
//     polygonA: &Entity,
//     polygonB: &Entity,
// ) -> (bool, Position, f32) {
//     // The normal will be the vector in wich the polygons should move to stop colliding
//     let mut normal = Position { x: 0.0, y: 0.0 };
//     // The depth is the amount of overlapping between both entities
//     let mut depth: f32 = f32::MAX;

//     let mut axis: Position;

//     // Check normal and depth for polygonA
//     for current in 0..polygonA.vertices.len() {
//         let mut next = current + 1;
//         if next == polygonA.vertices.len() {
//             next = 0
//         };
//         let va = polygonA.vertices[current];
//         let vb = polygonA.vertices[next];

//         let edge = Position::sub(va, vb);
//         axis = Position {
//             x: -edge.y,
//             y: edge.x,
//         };
//         // FIXME normalizing on this loop may be bad
//         axis.normalize();
//         let (min_a, max_a) = project_vertices(&polygonA.vertices, axis);
//         let (min_b, max_b) = project_vertices(&polygonB.vertices, axis);

//         // If there's a gap between the polygon it means they do not collide and we can safely return false
//         if min_a >= max_b || min_b >= max_a {
//             return (false, normal, depth);
//         }

//         let depth_a = max_b - min_a;
//         let depth_b = max_a - min_b;
//         let axis_depth = f32::min(depth_a, depth_b);

//         if axis_depth < depth {
//             depth = axis_depth;
//             if depth_b > depth_a {
//                 normal = Position {
//                     x: -axis.x,
//                     y: -axis.y,
//                 };
//             } else {
//                 normal = axis;
//             }
//         }
//     }
//     // Check normal and depth for polygonB
//     for current in 0..polygonB.vertices.len() {
//         let mut next = current + 1;
//         if next == polygonB.vertices.len() {
//             next = 0
//         };
//         let va = polygonB.vertices[current];
//         let vb = polygonB.vertices[next];

//         let edge = Position::sub(va, vb);
//         axis = Position {
//             x: -edge.y,
//             y: edge.x,
//         };
//         // FIXME normalizing on this loop may be bad
//         axis.normalize();
//         let (min_a, max_a) = project_vertices(&polygonB.vertices, axis);
//         let (min_b, max_b) = project_vertices(&polygonA.vertices, axis);

//         // If there's a gap between the polygon it means they do not collide and we can safely return false
//         if min_a >= max_b || min_b >= max_a {
//             return (false, normal, depth);
//         }

//         let depth_a = max_b - min_a;
//         let depth_b = max_a - min_b;
//         let axis_depth = f32::min(depth_a, depth_b);

//         if axis_depth < depth {
//             depth = axis_depth;
//             if depth_b > depth_a {
//                 normal = Position {
//                     x: -axis.x,
//                     y: -axis.y,
//                 };
//             } else {
//                 normal = axis;
//             }
//         }
//     }

//     (true, normal, depth)
// }

// Get the min and max values from a polygon projected on a specific axis
fn project_vertices(vertices: &Vec<Position>, axis: Position) -> (f32, f32) {
    let mut min = f32::MAX;
    let mut max = f32::MIN;

    for current in vertices {
        let projection = dot(current, axis);

        if projection < min {
            min = projection
        };
        if projection > max {
            max = projection
        };
    }

    (min, max)
}

// Get the min and max values from a circle projected on a specific axis
fn project_circle(circle: &Entity, axis: Position) -> (f32, f32) {
    let mut min;
    let mut max;

    let direction_radius = Position {
        x: axis.x * circle.radius,
        y: axis.y * circle.radius,
    };

    let position_plus_radius = Position::add(&circle.position, &direction_radius);
    let position_sub_radius = Position::sub(circle.position, direction_radius);

    min = dot(&position_plus_radius, axis);
    max = dot(&position_sub_radius, axis);

    if min > max {
        swap(&mut max, &mut min);
    }

    (min, max)
}

// Receives a position x and a vector of positions and returns the closest vector to the
// x position
fn find_closest_vertex(center: &Position, vertices: &Vec<Position>) -> Position {
    let mut result = Position { x: 0.0, y: 0.0 };
    let mut min_distance = f32::MAX;
    for current in vertices {
        let distance = center.distance_to_position(current);
        if distance < min_distance {
            min_distance = distance;
            result = *current;
        }
    }

    result
}

fn dot(a: &Position, b: Position) -> f32 {
    a.x * b.x + a.y * b.y
}

// We'll determine that an axis is invalid when both vertex that created that axis
// are in contact with another obstacle in the direction of the axis, to check this
// we'll cast a line from each vertex with a length of the cicle that's colliding and
// check if both casted lines are colliding with the same obstacle, if this is true
// it means that the axis is invalid since we'll end up inside another collider
fn invalid_axis(
    axis: Position,
    circle: &Entity,
    polygon: &Entity,
    current_vertex: &Position,
    next_vertex: &Position,
    obstacles: &HashMap<u64, Entity>,
) -> bool {
    let current_vertex_moved =
        Position::add(&current_vertex, &Position::mult(&axis, circle.radius));
    let mut current_vertex_line = Entity::new_line(
        polygon.id,
        vec![current_vertex.clone(), current_vertex_moved],
    );
    let current_vertex_collitions =
        current_vertex_line.collides_with(obstacles.clone().into_values().collect());

    let next_vertex_moved = Position::add(next_vertex, &Position::mult(&axis, circle.radius));
    let mut next_vertex_line =
        Entity::new_line(polygon.id, vec![next_vertex.clone(), next_vertex_moved]);
    let next_vertex_collitions =
        next_vertex_line.collides_with(obstacles.clone().into_values().collect());

    current_vertex_collitions
        .iter()
        .any(|collision_id| next_vertex_collitions.contains(collision_id))
}
