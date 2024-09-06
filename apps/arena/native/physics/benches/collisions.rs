use criterion::{criterion_group, criterion_main, Criterion};
use physics::{
    collision_detection::{line_line_collision, line_multiline_collision, line_polygon_collision},
    map::{Entity, Position},
};
use std::hint::black_box;

pub fn collisions_benchmark(c: &mut Criterion) {
    let new_pos = |i| Position::new(0.5 / i as f32, 1.5 * i as f32);
    //let circles = vec![
    let lines: Vec<_> = (0..1_000_000)
        .map(|i| Entity::new_polygon(i, vec![new_pos(i), new_pos(i+1), new_pos(i+2)]))
        .collect();
    //let points = 
    //let polygons = 
    c.bench_function(
        "line-line collisions",
        |b| b.iter(|| {
            let mut res = true;
            for l in lines.iter() {
                res = black_box(line_line_collision(black_box(&lines[3]), black_box(l)));
            }
            res
        })
    );
    let flat_lines: Vec<_> = lines.iter().map(|l| l.vertices.as_slice()).flatten().cloned().collect();
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
            for l in lines.iter() {
                res = black_box(line_polygon_collision(black_box(&lines[3]), black_box(l)));
            }
            res
        })
    );
}

criterion_group!(benches, collisions_benchmark);
criterion_main!(benches);
