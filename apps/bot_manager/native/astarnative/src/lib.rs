#![allow(non_snake_case)] // rustler macros generate non snake case names and dont use this allow themselves

mod position;

use std::collections::{BinaryHeap, HashMap};
use std::cmp::Ordering;

use position::Position;

const GRID_CELL_SIZE: f32 = 100.0;
const WORLD_RADIUS: f32 = 15000.0;
const NUM_ROWS: i64 = (WORLD_RADIUS * 2.0 / GRID_CELL_SIZE) as i64;
const NUM_COLS: i64 = (WORLD_RADIUS * 2.0 / GRID_CELL_SIZE) as i64;

enum AStarPathResult {
    Found(Vec<(i64, i64)>),
    NotFound,
}

#[rustler::nif()]
fn a_star_shortest_path(from: Position, to: Position) -> Vec<Position> {
    println!("BUILDING GRID");
    let mut grid : Vec<Vec<bool>> = vec![vec![false; NUM_COLS as usize]; NUM_ROWS as usize];
    lock_rectangle(&mut grid, world_to_grid(&Position{ x: 500.0, y: 500.0 }), world_to_grid(&Position {x: -500.0, y: -500.0}));
    lock_rectangle(&mut grid, world_to_grid(&Position{ x: 2500.0, y: 2500.0 }), world_to_grid(&Position {x: 2000.0, y: 2000.0}));
    lock_rectangle(&mut grid, world_to_grid(&Position{ x: -2500.0, y: -2500.0 }), world_to_grid(&Position {x: -2000.0, y: -2000.0}));
    lock_rectangle(&mut grid, world_to_grid(&Position{ x: -2500.0, y: 2500.0 }), world_to_grid(&Position {x: -2000.0, y: 2000.0}));
    lock_rectangle(&mut grid, world_to_grid(&Position{ x: 2500.0, y: -2500.0 }), world_to_grid(&Position {x: 2000.0, y: -2000.0}));

    lock_rectangle(&mut grid, world_to_grid(&Position{ x: 500.0, y: -3500.0 }), world_to_grid(&Position {x: -500.0, y: -2500.0}));
    lock_rectangle(&mut grid, world_to_grid(&Position{ x: 500.0, y: 3500.0 }), world_to_grid(&Position {x: -500.0, y: 2500.0}));
    lock_rectangle(&mut grid, world_to_grid(&Position{ x: -3500.0, y: 500.0 }), world_to_grid(&Position {x: -2500.0, y: -500.0}));
    lock_rectangle(&mut grid, world_to_grid(&Position{ x: 3500.0, y: 500.0 }), world_to_grid(&Position {x: 2500.0, y: -500.0}));

    for j in (NUM_ROWS / 2) - 5..=(NUM_ROWS / 2) + 5 {
        for i in (NUM_COLS / 2) - 5..=(NUM_COLS / 2) + 5 {
            grid[j as usize][i as usize] = true;
        }
    }

    println!("Casting world into grid positions for: {:?}, {:?}", from, to);

    let start = world_to_grid(&from);
    println!("start: {:?}", start);

    let goal = world_to_grid(&to);
    println!("goal: {:?}", goal);

    if let AStarPathResult::Found(path_in_grid) = a_star_find_path(start, goal, grid) {
        path_in_grid
            .iter()
            .map(grid_to_world)
            .collect::<Vec<Position>>()
    } else {
        Vec::new()
    }
}

fn lock_rectangle(grid: &mut Vec<Vec<bool>>, corner: (i64, i64), opposite_corner: (i64, i64)) {
    let from_x = i64::min(corner.0, opposite_corner.0);
    let to_x = i64::max(corner.0, opposite_corner.0);
    let from_y = i64::min(corner.1, opposite_corner.1);
    let to_y = i64::max(corner.1, opposite_corner.1);
    
    for j in from_y..=to_y {
        for i in from_x..=to_x {
            grid[j as usize][i as usize] = true;
        }
    }
}

#[derive(Clone, Copy, Eq, PartialEq)]
struct NodeEntry {
    node: (i64, i64),
    parent: (i64, i64),
    cost: usize,
    estimate_reach_cost: usize,
}

impl Ord for NodeEntry {
    fn cmp(&self, other: &Self) -> Ordering {
        other.estimate_reach_cost.cmp(&self.estimate_reach_cost)
    }
}

impl PartialOrd for NodeEntry {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

fn a_star_find_path(start: (i64, i64), goal: (i64, i64), grid: Vec<Vec<bool>>) -> AStarPathResult {
    // for each position on the grid, gets its parent node on the shortest path tree and the cost
    // to reach there
    let mut shortest_path_tree : HashMap<(i64, i64), (usize, (i64, i64))> = HashMap::new();

    let mut priority_queue = BinaryHeap::new();
    priority_queue.push(NodeEntry{node: start, parent: start, cost: 0, estimate_reach_cost: 0});

    while let Some(NodeEntry { node, parent, cost, estimate_reach_cost: _estimate_reach_cost }) = priority_queue.pop() {
        if shortest_path_tree.contains_key(&node) { continue; }

        shortest_path_tree.insert(node, (cost, parent));

        if node == goal {
            return AStarPathResult::Found(build_path(start, goal, &shortest_path_tree));
        }

        for neigh in get_neighbors(node, &grid) {
            if !shortest_path_tree.contains_key(&neigh) {
                priority_queue.push(NodeEntry { node: neigh, parent: node, cost: cost + 1, estimate_reach_cost: cost + 1 + heuristic_distance(neigh, goal) });
            }
        }
    }

    return AStarPathResult::NotFound;
}

fn build_path(start: (i64, i64), goal: (i64, i64), shortest_path_tree: &HashMap<(i64, i64), (usize, (i64, i64))>) -> Vec<(i64, i64)> {
    let mut current = goal;
    let mut path = Vec::new();

    path.push(goal);

    while current != start {
        current = shortest_path_tree[&current].1;
        path.push(current);
    }

    path.reverse();

    return path;
}

fn get_neighbors(pos: (i64, i64), grid: &[Vec<bool>]) -> Vec<(i64, i64)> {
    let mut neighbors = Vec::new();

    for (dy, dx) in [(-1, 0), (1, 0), (0, 1), (0, -1), (-1, -1), (-1, 1), (1, -1), (-1, -1)] {
        let neigh_pos = (pos.0 + dy, pos.1 + dx);

        if neigh_pos.0 >= 0 && neigh_pos.0 < NUM_ROWS && neigh_pos.1 >= 0 && neigh_pos.1 < NUM_COLS && !grid[neigh_pos.0 as usize][neigh_pos.1 as usize] {
            neighbors.push(neigh_pos);
        }
    }

    return neighbors;
}

fn heuristic_distance(from: (i64, i64), to: (i64, i64)) -> usize {
    (from.0.abs_diff(to.0) + from.1.abs_diff(to.1)) as usize
}

fn world_to_grid(pos: &Position) -> (i64, i64) {
    (
        ((pos.y + WORLD_RADIUS) / GRID_CELL_SIZE) as i64, 
        ((pos.x + WORLD_RADIUS) / GRID_CELL_SIZE) as i64
    )
}

fn grid_to_world(grid_pos: &(i64, i64)) -> Position {
    Position { 
        x: (grid_pos.1 - NUM_COLS / 2) as f32 * GRID_CELL_SIZE, 
        y: (grid_pos.0 - NUM_ROWS / 2) as f32 * GRID_CELL_SIZE 
    }
}

rustler::init!("Elixir.AStarNative", [a_star_shortest_path]);
