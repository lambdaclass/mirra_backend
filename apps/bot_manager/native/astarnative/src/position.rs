use rustler::NifMap;

#[derive(NifMap, Clone, Copy, Debug)]
pub struct Position {
    pub(crate) x: f32,
    pub(crate) y: f32,
}

impl Position {
    pub fn add(a: &Position, b: &Position) -> Position {
        Position {
            x: a.x + b.x,
            y: a.y + b.y,
        }
    }
}

impl PartialEq for Position {
    fn eq(&self, other: &Position) -> bool {
        self.x == other.x && self.y == other.y
    }
}
impl Eq for Position {}
