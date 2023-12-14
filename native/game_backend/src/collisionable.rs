use rustler::{NifMap, NifTaggedEnum};
use serde::Deserialize;

use crate::map::Position;

#[derive(Deserialize, NifTaggedEnum, Clone, PartialEq)]
pub enum CollisionableType {
    CircularSection,
}

#[derive(Deserialize)]
pub struct MapCollisionablesFile {
    map_collisionables: Vec<MapCollisionable>,
}

#[derive(Deserialize, NifMap)]
pub struct MapCollisionable {
    pub id: u64,
    pub collisionable_type: CollisionableType,
    pub position: Position,
    pub radius: u64,
}

pub fn parse_map_collisionables(data: &str) -> Vec<MapCollisionable> {
    let map_collisionables_file: MapCollisionablesFile = serde_json::from_str(data).unwrap();
    map_collisionables_file.map_collisionables
}
