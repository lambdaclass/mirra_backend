use rustler::NifMap;

#[derive(NifMap)]
pub struct Position {
    pub x: i64,
    pub y: i64,
}
