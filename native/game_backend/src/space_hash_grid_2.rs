use crate::{map::Position, player::Player};
use rustler::NifMap;
use std::collections::HashMap;

#[derive(Clone, Debug, rustler::NifMap)]
pub struct Vec2 {
    x: f32,
    y: f32,
}

impl From<Position> for Vec2 {
    fn from(value: Position) -> Self {
        let x = value.x as f32;
        let y = value.y as f32;
        Self { x, y }
    }
}

pub type Bucket = Vec<GameEntity>;

#[derive(Clone, Debug, rustler::NifMap)]
pub struct GameEntity {
    position: Vec2,
    radius: f32,
    pub id: u64,
}

impl From<&Player> for GameEntity {
    fn from(player: &Player) -> GameEntity {
        let position = player.position.into();
        let radius = player.size as f32;
        let id = player.id;
        GameEntity {
            position,
            radius,
            id: id,
        }
    }
}

#[derive(NifMap)]
pub struct SpatialHashGrid {
    cols: u64,
    rows: u64,
    bucket_total: u64,
    buckets: HashMap<u64, Bucket>,
    sceneheight: u64,
    cellsize: u64,
    scenewidth: u64,
}

impl SpatialHashGrid {
    pub fn new(scenewidth: u64, sceneheight: u64, cellsize: u64) -> Self {
        // let cols = scenewidth / cellsize;
        // let rows = sceneheight / cellsize;
        let cols = 1000;
        let rows = 1000;
        let bucket_total = cols*rows;
        let mut buckets = HashMap::new();
        for i in 0..bucket_total {
            buckets.insert(i, vec![]);
        }
        SpatialHashGrid {
            cols,
            rows,
            bucket_total,
            buckets,
            sceneheight,
            cellsize,
            scenewidth,
        }
    }
    pub fn clear_buckets(&mut self) {
        self.buckets = HashMap::new();
        let mocked_entity = GameEntity {
            position: Vec2 { x: 1f32, y: 1f32 },
            radius: 1f32,
            id: (2_u64 << 32),
        };
        for i in 0..self.bucket_total {
            self.buckets.insert(i, vec![mocked_entity.clone()]);
        }
    }
    pub fn register_entity(&mut self, entity: &GameEntity) {
        let cell_ids = self.calculate_ids_for(entity);
        for (indx, ref id) in cell_ids.iter().enumerate() {
            let bucket = self
                .buckets
                .get_mut(id)
                .expect(&format!("Grid not defined at: {id} with index: {indx}"));
            bucket.push(entity.clone());
        }
    }

    pub fn calculate_ids_for(&self, entity: &GameEntity) -> Vec<u64> {
        let mut buckets_entity_is_in = vec![];
        let min = Vec2 {
            x: entity.position.x - entity.radius,
            y: entity.position.y - entity.radius,
        };
        let max = Vec2 {
            x: entity.position.x + entity.radius,
            y: entity.position.y + entity.radius,
        };
        let width = self.scenewidth / self.cellsize;
        let top_left = min.clone();
        let top_right = Vec2 { x: max.x, y: min.y };
        let bottom_right = Vec2 { x: max.x, y: max.y };
        let bottom_left = Vec2 { x: min.x, y: max.y };
        let positions_entity_touches = vec![top_left, top_right, bottom_right, bottom_left];
        // println!("{:?}", positions_entity_touches);
        for position in positions_entity_touches {
            self.add_to_bucket(position, width as f32, &mut buckets_entity_is_in)
        }
        return buckets_entity_is_in;
    }

    pub fn add_to_bucket(&self, vec: Vec2, width: f32, bucket: &mut Vec<u64>) {
        let x_ref = (vec.x / (self.cellsize as f32));
        let y_ref = (vec.y / (self.cellsize as f32));
        let cell_position = ((x_ref + y_ref) * width).floor();
        // println!("x: {}, y: {}, cell_pos: {}", x_ref, y_ref, cell_position);
        bucket.push(cell_position as u64);
    }

    pub fn get_nearby(&self, entity: &GameEntity) -> Vec<u64> {
        let vec: Vec<GameEntity> = vec![];
        return self.calculate_ids_for(entity);
    }

    pub fn game_entities_at(&self, id: u64) -> &Bucket {
        self.buckets.get(&id).expect(&format!("{id} is not known"))
    }
}
