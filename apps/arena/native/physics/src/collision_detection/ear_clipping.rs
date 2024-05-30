use crate::map::{Entity, Position};

/*
Ear clipping triangulation algorithm

To summarize the algorithm works by traversing the vertices from a polygon finding ears an deleting the current vertex
from the polygon shape and repeat until there's 3 vertices in the polygon

An ear is defined by the following:
 a. It's a triangle formed by the current vertex we're traversing, the previous one and the next
 b. The inner angle formed by the three vertices aren't greater than 180 degrees
 c. There isn't any vertex inside the triangle area

The logic of the algorithm goes like this:
1. Traverse the polygon looking for ears
2. Once we find an ear do the following:
   - Save the triangle formed by the current previous and next vertex
   - Delete the current vertex from the available vertex list
   - Start again with the cleaned up vertex list until the list length is 3
3. Make a final triangle with the 3 remaining vertices

Even though the resolution is different, the logic is the same as the following article:
- [Geometric tools article](https://www.geometrictools.com/Documentation/TriangulationByEarClipping.pdf)

*/

pub(crate) fn maybe_triangulate_polygon(mut polygon: Entity) -> Vec<Entity> {
    remove_redundant_vertices(&mut polygon);
    if is_polygon_convex(&polygon) {
        return vec![polygon.clone()];
    }
    triangulate_polygon(&polygon)
}

// Remove redundant vertices.
// A redundant vertex is one that is in the middle of a straight line drawn by two other vertices.
fn remove_redundant_vertices(polygon: &mut Entity) {
    let mut cleaned_vertices = vec![];
    for current_vertex_index in 0..polygon.vertices.len() {
        let previous_vertex_index =
            get_previous_vertex_index(current_vertex_index, &polygon.vertices);
        let next_vertex_index = get_next_vertex_index(current_vertex_index, &polygon.vertices);

        let previous_vertex = polygon.vertices[previous_vertex_index];
        let current_vertex = polygon.vertices[current_vertex_index];
        let next_vertex = polygon.vertices[next_vertex_index];

        if !is_vertex_consecutive(&previous_vertex, &current_vertex, &next_vertex) {
            cleaned_vertices.push(current_vertex);
        }
    }

    polygon.vertices = cleaned_vertices;
}

fn is_vertex_consecutive(
    previous_vertex: &Position,
    current_vertex: &Position,
    next_vertex: &Position,
) -> bool {
    let current_to_previous_vector = Position::sub(previous_vertex, current_vertex);
    let current_to_next_vector = Position::sub(next_vertex, current_vertex);

    get_cross_product_value(&current_to_previous_vector, &current_to_next_vector) == 0.0
}

fn triangulate_polygon(polygon: &Entity) -> Vec<Entity> {
    let mut result: Vec<Entity> = vec![];
    let mut vertices = polygon.vertices.clone();
    let mut ear_found: bool;

    while vertices.len() > 3 {
        ear_found = false;
        for current_vertex_index in 0..vertices.len() {
            let previous_vertex_index = get_previous_vertex_index(current_vertex_index, &vertices);
            let next_vertex_index = get_next_vertex_index(current_vertex_index, &vertices);

            let previous_vertex = vertices[previous_vertex_index];
            let current_vertex = vertices[current_vertex_index];
            let next_vertex = vertices[next_vertex_index];
            let candidate_triangle =
                Entity::new_polygon(1, vec![previous_vertex, current_vertex, next_vertex]);
            if is_triangle_ear(&candidate_triangle, &vertices) {
                ear_found = true;
                result.push(candidate_triangle);
                vertices.retain(|pos| pos != &current_vertex);
                break;
            }
        }

        if !ear_found {
            panic!("No ear detected, polygon invalid")
        }
    }
    let previous_vertex = vertices[0];
    let current_vertex = vertices[1];
    let next_vertex = vertices[2];

    let candidate_triangle =
        Entity::new_polygon(1, vec![previous_vertex, current_vertex, next_vertex]);
    result.push(candidate_triangle);

    // This algorithm should always result n - 2 triangles where n is the amount of vertex
    // in the polygon
    if result.len() > polygon.vertices.len() - 2 {
        panic!("Wrong triangulation result")
    }

    result
}

// Check if the three vertices are a valid ear, this means
// 1. The inner angle formed by the three vertices aren't greater than 180 degrees
// 2. There isn't any vertex inside the triangle area
fn is_triangle_ear(triangle: &Entity, vertices: &Vec<Position>) -> bool {
    let previous_vertex = triangle.vertices[0];
    let current_vertex = triangle.vertices[1];
    let next_vertex = triangle.vertices[2];

    let current_to_previous_vector = Position::sub(&previous_vertex, &current_vertex);
    let current_to_next_vector = Position::sub(&next_vertex, &current_vertex);

    let triangle_has_point_inside = triangle_has_point_inside(triangle, vertices);

    get_cross_product_value(&current_to_previous_vector, &current_to_next_vector) > 0.0
        && !triangle_has_point_inside
}

// Check if any vertex beside the one that belongs to the triangle is inside the triangle area
fn triangle_has_point_inside(triangle: &Entity, vertex: &Vec<Position>) -> bool {
    let vector_from_a_to_b = Position::sub(&triangle.vertices[1], &triangle.vertices[0]);
    let vector_from_b_to_c = Position::sub(&triangle.vertices[2], &triangle.vertices[1]);
    let vector_from_c_to_a = Position::sub(&triangle.vertices[0], &triangle.vertices[2]);

    let mut result = false;
    for v in vertex {
        if triangle.vertices.contains(v) {
            continue;
        }

        let vector_a_to_v = Position::sub(v, &triangle.vertices[0]);
        let vector_b_to_v = Position::sub(v, &triangle.vertices[1]);
        let vector_c_to_v = Position::sub(v, &triangle.vertices[2]);

        // Cross product between A->B with A->V
        let first_cross_product = get_cross_product_value(&vector_from_a_to_b, &vector_a_to_v);
        // Cross product between B->C with B->V
        let second_cross_product = get_cross_product_value(&vector_from_b_to_c, &vector_b_to_v);
        // Cross product between C->A with C->V
        let third_cross_product = get_cross_product_value(&vector_from_c_to_a, &vector_c_to_v);

        result = result
            || (first_cross_product < 0.0
                && second_cross_product < 0.0
                && third_cross_product < 0.0);
    }

    result
}

// Usually cross product results in another vector but since this is a two dimensional vector and
// We just wanna use the value from this result we're going to return a numerical value
fn get_cross_product_value(first_vector: &Position, second_vector: &Position) -> f32 {
    first_vector.x * second_vector.y - first_vector.y * second_vector.x
}

// A convex polygon means that every inner angle doesn't have more than
// 180 degrees
fn is_polygon_convex(polygon: &Entity) -> bool {
    let mut result = true;
    for current_vertex_index in 0..polygon.vertices.len() {
        let previous_vertex_index =
            get_previous_vertex_index(current_vertex_index, &polygon.vertices);
        let next_vertex_index = get_next_vertex_index(current_vertex_index, &polygon.vertices);

        let previous_vertex = polygon.vertices[previous_vertex_index];
        let current_vertex = polygon.vertices[current_vertex_index];
        let next_vertex = polygon.vertices[next_vertex_index];

        let first_vector = Position::sub(&previous_vertex, &current_vertex);
        let second_vector = Position::sub(&next_vertex, &current_vertex);

        result = result && get_cross_product_value(&first_vector, &second_vector) >= 0.0;
    }

    result
}

fn get_previous_vertex_index(index: usize, vector: &[Position]) -> usize {
    if index == 0 {
        vector.len() - 1
    } else {
        index - 1
    }
}

fn get_next_vertex_index(index: usize, vector: &[Position]) -> usize {
    if index == vector.len() - 1 {
        0
    } else {
        index + 1
    }
}
