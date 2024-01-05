use rustler::NifMap;

#[derive(NifMap, Clone)]
pub struct Player {
    pub(crate) id: u64,
    pub(crate) position: Position,
    pub(crate) size: f64,
    life: u64,
    pub(crate) speed: f64,
}

#[derive(NifMap, Clone, Debug)]
pub struct Position {
    pub(crate) x: f64,
    pub(crate) y: f64,
}

impl Player {
    pub fn new(id: u64, initial_position: Position, size: f64, life: u64, speed: f64) -> Player {
        Player {
            id,
            position: initial_position,
            size,
            life,
            speed,
        }
    }
}
