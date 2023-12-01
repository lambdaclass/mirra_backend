use itertools::Itertools;
use std::collections::HashMap;

#[derive(Clone, Debug)]
pub struct Vec2 {
    x: f32,
    y: f32,
}
pub type Bucket = Vec<GameEntity>;

#[derive(Clone, Debug)]
pub struct GameEntity {
    position: Vec2,
    radius: f32,
}

pub struct SpatialHashGrid {
    cols: u64,
    rows: u64,
    buckets: HashMap<u64, Bucket>,
    sceneheight: u64,
    cellsize: u64,
    scenewidth: u64,
}

impl SpatialHashGrid {
    pub fn new(scenewidth: u64, sceneheight: u64, cellsize: u64) -> Self {
        let cols = scenewidth / cellsize;
        let rows = sceneheight / cellsize;
        let mut buckets = HashMap::with_capacity((cols * rows) as usize);
        for i in 0..(cols * rows) {
            buckets.insert(i, vec![]);
        }
        SpatialHashGrid {
            cols,
            rows,
            buckets,
            sceneheight,
            cellsize,
            scenewidth,
        }
    }
    pub fn clear_buckets(&mut self) {
        self.buckets.clear();
        let buckets = self.cols * self.rows;
        for i in 0..buckets {
            self.buckets.insert(i, vec![]);
        }
    }
    pub fn register_entity(&mut self, entity: &GameEntity) {
        let cell_ids = self.calculate_id_for(entity);
        for ref id in cell_ids {
            let mut bucket = self.buckets.get_mut(id).expect("Grid not defined at: {id}");
            bucket.push(entity.clone());
        }
    }

    pub fn calculate_id_for(&self, entity: &GameEntity) -> Vec<u64> {
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
        for position in positions_entity_touches {
            self.add_to_bucket(position, width as f32, &mut buckets_entity_is_in)
        }
        return buckets_entity_is_in;
    }

    pub fn add_to_bucket(&self, vec: Vec2, width: f32, bucket: &mut Vec<u64>) {
        let x_ref = (vec.x / (self.cellsize as f32));
        let y_ref = (vec.y / (self.cellsize as f32));
        let cell_position = ((x_ref + y_ref) * width).floor();
        bucket.push(cell_position as u64);
    }

    pub fn get_nearby(&self, entity: &GameEntity) -> Vec<u64> {
        let vec: Vec<GameEntity> = vec![];
        return self.calculate_id_for(entity);
    }
}
