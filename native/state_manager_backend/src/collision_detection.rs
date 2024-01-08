use crate::map::{Entity, Position};

pub(crate) fn point_circle_collision(point: &Entity, circle: &Entity) -> bool {
    let distance = calculate_distance(&point.position, &circle.position);
    distance <= circle.radius
}

pub(crate) fn line_circle_collision(line: &Entity, circle: &Entity) -> bool {
    let point_1 = Entity::new_point(0, line.vertices[0]);
    let inside_1 = point_circle_collision(&point_1, circle);
    let point_2 = Entity::new_point(0, line.vertices[1]);
    let inside_2 = point_circle_collision(&point_2, circle);
    if inside_1 || inside_2 {
        return true;
    };

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

    let on_line = line_point_colision(line, &closest_point);
    if !on_line {
        return false;
    };

    let dist_x = closest_point.position.x - circle.position.x;
    let dist_y = closest_point.position.y - circle.position.y;

    let distance = ((dist_x * dist_x) + (dist_y * dist_y)).sqrt();

    distance <= circle.radius
}

pub(crate) fn circle_circle_collision(circle_1: &Entity, circle_2: &Entity) -> bool {
    let distance = calculate_distance(&circle_1.position, &circle_2.position);
    distance <= circle_1.radius + circle_2.radius
}

pub(crate) fn circle_polygon_collision(circle: &Entity, polygon: &Entity) -> bool {
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

    point_polygon_colision(circle, polygon)
}

pub(crate) fn line_point_colision(line: &Entity, point: &Entity) -> bool {
    let d1 = calculate_distance(&point.position, &line.vertices[0]);
    let d2 = calculate_distance(&point.position, &line.vertices[1]);
    let line_length = calculate_distance(&line.vertices[0], &line.vertices[1]);

    let buffer = 0.1;

    d1 + d2 >= line_length - buffer && d1 + d2 <= line_length + buffer
}

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
            && (point.position.x < (next_vertex.x - current_vertex.x)
                * (point.position.y - current_vertex.y)
                / (next_vertex.y - current_vertex.y)
                + current_vertex.x)
        {
            collision = !collision;
        }
    }

    collision
}

pub(crate) fn calculate_distance(a: &Position, b: &Position) -> f64 {
    let x = a.x - b.x;
    let y = a.y - b.y;
    (x.powi(2) + y.powi(2)).sqrt()
}
