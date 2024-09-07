use criterion::{criterion_group, criterion_main, Criterion};
use physics::{
    collision_detection::{
        line_line_collision, line_multiline_collision, line_polygon_collision, point_polygon_collision,
        sat::intersect_circle_polygon,
    },
    map::{Entity, Position},
};
use std::collections::HashMap;
use std::hint::black_box;

pub fn collisions_benchmark(c: &mut Criterion) {
    let new_pos = |i| Position::new(0.5 / i as f32, 1.5 * i as f32);
    let circle = Entity::new_circle(u64::MAX, new_pos(0), 0.2);
    let external_wall = Entity::new_polygon(u64::MAX, vec![
        Position::new(-100.0, 100.0), Position::new(100.0, 100.0),
        Position::new(100.0, -100.0), Position::new(100.0, -100.0),
    ]);

    let polygons: Vec<_> = (0..1_000_000)
        .map(|i| Entity::new_polygon(i, vec![new_pos(i), new_pos(i+1), new_pos(i+2)]))
        .collect();

    c.bench_function(
        "intersect_circle_polygon",
        |b| b.iter(|| {
            let mut res = (true, Position::new(1., 1.), 1.1);
            // OK to use polygons as lines, extra vertices simply get ignored
            for l in polygons[..15000].iter() {
                res = black_box(intersect_circle_polygon(black_box(&circle), black_box(l), &polygons, &external_wall));
            }
            res
        })
    );

    c.bench_function(
        "line-line collisions",
        |b| b.iter(|| {
            let mut res = true;
            // OK to use polygons as lines, extra vertices simply get ignored
            for l in polygons.iter() {
                res = black_box(line_line_collision(black_box(&polygons[3]), black_box(l)));
            }
            res
        })
    );

    // OK to use polygons as lines, extra vertices simply get ignored, but take the first two
    // of each before flattening to make a fair comparison, otherwise we'd have more lines
    let flat_lines: Vec<_> = polygons.iter().map(|l| &l.vertices[..2]).flatten().cloned().collect();
    c.bench_function(
        "multi-line collisions",
        |b| b.iter(|| {
            let mut collisions = vec![false; flat_lines.len()];
            black_box(line_multiline_collision(black_box(&flat_lines[6..8]), black_box(flat_lines.as_slice()), &mut collisions));
        })
    );

    c.bench_function(
        "line-polygon collisions",
        |b| b.iter(|| {
            let mut res = true;
            for l in polygons.iter() {
                res = black_box(line_polygon_collision(black_box(&polygons[3]), black_box(l)));
            }
            res
        })
    );

    c.bench_function(
        "point-polygon collisions",
        |b| b.iter(|| {
            let mut res = true;
            for l in polygons.iter() {
                res = black_box(point_polygon_collision(black_box(&polygons[3]), black_box(l)));
            }
            res
        })
    );
}

criterion_group!(benches, collisions_benchmark);
criterion_main!(benches);
