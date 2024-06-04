use crate::map::{Entity, Position};
pub mod ear_clipping;
pub mod sat;
/*
 * Determines if a collision has occured between a point and a circle
 * If the distance between the point and the center of the circle is less
 * than the radius of the circle, a collision has occured
 */
pub(crate) fn point_circle_collision(point: &Entity, circle: &Entity) -> bool {
    let distance = calculate_distance(&point.position, &circle.position);
    distance <= circle.radius
}

/*
 * Determines if a collision has occured between a line and a circle
 * If the distance between the center of the circle and the closest point
 * of the line is less than the radius of the circle, a collision has occured
 * Also that closest point should be on the segment
 */
pub(crate) fn line_circle_collision(line: &Entity, circle: &Entity) -> bool {
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
    let line_length = ((dist_x * dist_x) + (dist_y * dist_y)).sqrt();

    let dot = (((circle.position.x - point_1.position.x)
        * (point_2.position.x - point_1.position.x))
        + ((circle.position.y - point_1.position.y) * (point_2.position.y - point_1.position.y)))
        / line_length.powi(2);

    let closest_point = Entity::new_point(
        0,
        Position {
            x: point_1.position.x + (dot * (point_2.position.x - point_1.position.x)),
            y: point_1.position.y + (dot * (point_2.position.y - point_1.position.y)),
        },
    );

    // Check if the closest point is on the line
    let on_line = line_point_colision(line, &closest_point);
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
pub(crate) fn circle_circle_collision(circle_1: &Entity, circle_2: &Entity) -> bool {
    let distance = calculate_distance(&circle_1.position, &circle_2.position);
    distance <= circle_1.radius + circle_2.radius
}

/*
 * Determines if a collision has occured between a circle and a polygon
 *
 */
pub(crate) fn circle_polygon_collision(circle: &Entity, polygon: &Entity) -> bool {
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
    // return false instead of calling point_polygon_colision
    point_polygon_colision(circle, polygon)
}

/*
 * Determines if a collision has occured between a line and a polygon
 * If the distance between vertex 1 and the point and vertex 2 and the point
 * is equal (with a little bufer) to the distance between vertex 1 and vertex 2,
 * a collision has occured
 */
pub(crate) fn line_point_colision(line: &Entity, point: &Entity) -> bool {
    let d1 = calculate_distance(&point.position, &line.vertices[0]);
    let d2 = calculate_distance(&point.position, &line.vertices[1]);
    let line_length = calculate_distance(&line.vertices[0], &line.vertices[1]);

    let buffer = 0.1;

    d1 + d2 >= line_length - buffer && d1 + d2 <= line_length + buffer
}

/*
 * Determines if a collision has occured between a point and a polygon
 */
pub(crate) fn point_polygon_colision(point: &Entity, polygon: &Entity) -> bool {
    let mut collision = false;
    for current in 0..polygon.vertices.len() {
        let mut next = current + 1;
        if next == polygon.vertices.len() {
            next = 0
        };

        let current_vertex = polygon.vertices[current];
        let next_vertex = polygon.vertices[next];

        if ((current_vertex.y >= point.position.y && next_vertex.y < point.position.y)
            || (current_vertex.y < point.position.y && next_vertex.y >= point.position.y))
            && (point.position.x
                < (next_vertex.x - current_vertex.x) * (point.position.y - current_vertex.y)
                    / (next_vertex.y - current_vertex.y)
                    + current_vertex.x)
        {
            collision = !collision;
        }
    }

    collision
}

pub(crate) fn line_polygon_collision(line: &Entity, polygon: &Entity) -> bool {
    for current_vertex_index in 0..polygon.vertices.len() {
        let mut next_vertex_index = current_vertex_index + 1;
        if next_vertex_index == polygon.vertices.len() {
            next_vertex_index = 0
        };
        let current_vertex = polygon.vertices[current_vertex_index];
        let next_vertex = polygon.vertices[next_vertex_index];

        let polygon_line = Entity::new_line(1, vec![current_vertex, next_vertex]);

        if line_line_collision(line, &polygon_line) {
            return true;
        }
    }

    false
}

pub(crate) fn line_line_collision(line: &Entity, other_line: &Entity) -> bool {
    let line_first_vertex = line.vertices[0];
    let line_second_vertex = line.vertices[1];
    let other_line_first_vertex = other_line.vertices[0];
    let other_line_second_vertex = other_line.vertices[1];

    let uA = ((other_line_second_vertex.x - other_line_first_vertex.x)
        * (line_first_vertex.y - other_line_first_vertex.y)
        - (other_line_second_vertex.y - other_line_first_vertex.y)
            * (line_first_vertex.x - other_line_first_vertex.x))
        / ((other_line_second_vertex.y - other_line_first_vertex.y)
            * (line_second_vertex.x - line_first_vertex.x)
            - (other_line_second_vertex.x - other_line_first_vertex.x)
                * (line_second_vertex.y - line_first_vertex.y));

    let uB = ((line_second_vertex.x - line_first_vertex.x)
        * (line_first_vertex.y - other_line_first_vertex.y)
        - (line_second_vertex.y - line_first_vertex.y)
            * (line_first_vertex.x - other_line_first_vertex.x))
        / ((other_line_second_vertex.y - other_line_first_vertex.y)
            * (line_second_vertex.x - line_first_vertex.x)
            - (other_line_second_vertex.x - other_line_first_vertex.x)
                * (line_second_vertex.y - line_first_vertex.y));

    (0.0..=1.0).contains(&uA) && (0.0..=1.0).contains(&uB)
}

/*
 * Calculates the distance between two positions
 */
pub(crate) fn calculate_distance(a: &Position, b: &Position) -> f32 {
    let x = a.x - b.x;
    let y = a.y - b.y;
    (x.powi(2) + y.powi(2)).sqrt()
}
