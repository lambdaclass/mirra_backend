use crate::map::{Entity, Position};
pub mod ear_clipping;
pub mod sat;
/*
 * Determines if a collision has occured between a point and a circle
 * If the distance between the point and the center of the circle is less
 * than the radius of the circle, a collision has occured
 */
pub fn point_circle_collision(point: &Entity, circle: &Entity) -> bool {
    let distance = calculate_distance(&point.position, &circle.position);
    distance <= circle.radius
}
pub fn point_polygon_collision(point: &Entity, polygon: &Entity) -> bool {
    let mut collisions = 0;
    let mut current_vertex;
    let mut next_vertex = polygon.vertices[polygon.vertices.len()-1];
    let mut i = 0;
    while i < polygon.vertices.len() {
        current_vertex = next_vertex;
        next_vertex = polygon.vertices[i];
        i += 1;

        collisions += (point.position.y != point.position.y.min(current_vertex.y).min(next_vertex.y) &&
                (point.position.y != point.position.y.max(current_vertex.y).max(next_vertex.y))
            && (point.position.x - current_vertex.x) * (next_vertex.y - current_vertex.y)
                < (next_vertex.x - current_vertex.x) * (point.position.y - current_vertex.y)) as usize;
    }

    collisions != 0
}

/*
 * Determines if a collision has occured between a line and a circle
 * If the distance between the center of the circle and the closest point
 * of the line is less than the radius of the circle, a collision has occured
 * Also that closest point should be on the segment
 */
pub fn line_circle_collision(line: &Entity, circle: &Entity) -> bool {
    // Check if the vertices are inside the circle
    let point_1 = Entity::new_point(0, line.vertices[0]);
    let inside_1 = point_circle_collision(&point_1, circle);
    let point_2 = Entity::new_point(0, line.vertices[1]);
    let inside_2 = point_circle_collision(&point_2, circle);
    if inside_1 || inside_2 {
        return true;
    };

    // Find the closest point on the line to the circle
    let dist_x = point_1.position.x - point_2.position.x;
    let dist_y = point_1.position.y - point_2.position.y;
    let line_length_squared = (dist_x * dist_x) + (dist_y * dist_y);

    let dot = (((circle.position.x - point_1.position.x)
        * (point_2.position.x - point_1.position.x))
        + ((circle.position.y - point_1.position.y) * (point_2.position.y - point_1.position.y)))
        / line_length_squared;

    let closest_point = Entity::new_point(
        0,
        Position {
            x: point_1.position.x + (dot * (point_2.position.x - point_1.position.x)),
            y: point_1.position.y + (dot * (point_2.position.y - point_1.position.y)),
        },
    );

    // Check if the closest point is on the line
    let on_line = line_point_collision(line, &closest_point);
    if !on_line {
        return false;
    };

    // Check if the closest point is inside the circle
    point_circle_collision(&closest_point, circle)
}

/*
 * Determines if a collision has occured between two circles
 * If the distance between the centers of the circles is less than
 * the sum of the radius, a collision has occured
 */
pub fn circle_circle_collision(circle_1: &Entity, circle_2: &Entity) -> bool {
    let distance = calculate_distance(&circle_1.position, &circle_2.position);
    distance <= circle_1.radius + circle_2.radius
}

/*
 * Determines if a collision has occured between a circle and a polygon
 *
 */
pub fn circle_polygon_collision(circle: &Entity, polygon: &Entity) -> bool {
    // For each line in the polygon, check if there is a collision between the line and the circle
    // If there is a collision, return true
    for current in 0..polygon.vertices.len() {
        let mut next = current + 1;
        if next == polygon.vertices.len() {
            next = 0
        };

        let current_line =
            Entity::new_line(0, vec![polygon.vertices[current], polygon.vertices[next]]);

        let collision = line_circle_collision(&current_line, circle);
        if collision {
            return true;
        };
    }

    // Check if the center of the circle is inside the polygon
    // If you doesn't want to check if the circle is inside the polygon,
    // return false instead of calling point_polygon_collision
    point_polygon_collision(circle, polygon)
}

/*
 * Determines if a collision has occured between a line and a polygon
 * If the distance between vertex 1 and the point and vertex 2 and the point
 * is equal (with a little bufer) to the distance between vertex 1 and vertex 2,
 * a collision has occured
 */
pub fn line_point_collision(line: &Entity, point: &Entity) -> bool {
    let d1 = calculate_distance(&point.position, &line.vertices[0]);
    let d2 = calculate_distance(&point.position, &line.vertices[1]);
    let line_length = calculate_distance(&line.vertices[0], &line.vertices[1]);

    let buffer = 0.1;

    d1 + d2 >= line_length - buffer && d1 + d2 <= line_length + buffer
}

pub fn line_polygon_collision(line: &Entity, polygon: &Entity) -> bool {
    debug_assert_eq!(line.vertices.len(), 2);

    let line_first_vertex = line.vertices[0];
    let line_second_vertex = line.vertices[1];

    let mut collisions = 0;
    let mut other_line_first_vertex;
    let mut other_line_second_vertex = polygon.vertices[polygon.vertices.len()-1];
    let mut i = 0;
    while i < polygon.vertices.len() {
        other_line_first_vertex = other_line_second_vertex;
        other_line_second_vertex = polygon.vertices[i];
        i += 1;

        let f = ((other_line_second_vertex.y - other_line_first_vertex.y)
                * (line_second_vertex.x - line_first_vertex.x)
                - (other_line_second_vertex.x - other_line_first_vertex.x)
                    * (line_second_vertex.y - line_first_vertex.y)).recip();

        let uA = ((other_line_second_vertex.x - other_line_first_vertex.x)
            * (line_first_vertex.y - other_line_first_vertex.y)
            - (other_line_second_vertex.y - other_line_first_vertex.y)
                * (line_first_vertex.x - other_line_first_vertex.x))
            * f;

        let uB = ((line_second_vertex.x - line_first_vertex.x)
            * (line_first_vertex.y - other_line_first_vertex.y)
            - (line_second_vertex.y - line_first_vertex.y)
                * (line_first_vertex.x - other_line_first_vertex.x))
            * f;

        collisions += 
            (0.0..=1.0)
            .contains(&uA)
            as usize
            &
            (0.0..=1.0)
            .contains(&uB)
            as usize;
    }
    collisions != 0
}

pub fn line_line_collision(line: &Entity, other_line: &Entity) -> bool {
    let line_first_vertex = line.vertices[0];
    let line_second_vertex = line.vertices[1];
    let other_line_first_vertex = other_line.vertices[0];
    let other_line_second_vertex = other_line.vertices[1];

    let f = ((other_line_second_vertex.y - other_line_first_vertex.y)
            * (line_second_vertex.x - line_first_vertex.x)
            - (other_line_second_vertex.x - other_line_first_vertex.x)
                * (line_second_vertex.y - line_first_vertex.y)).recip();

    let uA = ((other_line_second_vertex.x - other_line_first_vertex.x)
        * (line_first_vertex.y - other_line_first_vertex.y)
        - (other_line_second_vertex.y - other_line_first_vertex.y)
            * (line_first_vertex.x - other_line_first_vertex.x))
        * f;
        
    let uB = ((line_second_vertex.x - line_first_vertex.x)
        * (line_first_vertex.y - other_line_first_vertex.y)
        - (line_second_vertex.y - line_first_vertex.y)
            * (line_first_vertex.x - other_line_first_vertex.x))
        * f;

    (0.0..=1.0).contains(&uA) && (0.0..=1.0).contains(&uB)
}

pub fn line_multiline_collision(line: &[Position], other_lines: &[Position], collisions: &mut [bool]) {
    debug_assert_eq!(line.len(), 2);
    debug_assert_eq!(other_lines.len() % 2, 0);
    debug_assert_eq!(other_lines.len() / 2, collisions.len());

    let line_first_vertex = line[0];
    let line_second_vertex = line[1];

    for (i, other_line) in other_lines.chunks_exact(2).enumerate() {
        let other_line_first_vertex = other_line[0];
        let other_line_second_vertex = other_line[1];

        let f = ((other_line_second_vertex.y - other_line_first_vertex.y)
                * (line_second_vertex.x - line_first_vertex.x)
                - (other_line_second_vertex.x - other_line_first_vertex.x)
                    * (line_second_vertex.y - line_first_vertex.y)).recip();

        let uA = ((other_line_second_vertex.x - other_line_first_vertex.x)
            * (line_first_vertex.y - other_line_first_vertex.y)
            - (other_line_second_vertex.y - other_line_first_vertex.y)
                * (line_first_vertex.x - other_line_first_vertex.x))
            * f;
            
        let uB = ((line_second_vertex.x - line_first_vertex.x)
            * (line_first_vertex.y - other_line_first_vertex.y)
            - (line_second_vertex.y - line_first_vertex.y)
                * (line_first_vertex.x - other_line_first_vertex.x))
            * f;

        collisions[i] = (0.0..=1.0).contains(&uA) && (0.0..=1.0).contains(&uB);
    }
}

/*
 * Calculates the distance between two positions
 */
pub(crate) fn calculate_distance(a: &Position, b: &Position) -> f32 {
    let x = a.x - b.x;
    let y = a.y - b.y;
    (x.powi(2) + y.powi(2)).sqrt()
}
