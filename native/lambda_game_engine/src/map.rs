use rustler::NifMap;

#[derive(NifMap)]
pub struct Position {
    pub x: u64,
    pub y: u64,
}
