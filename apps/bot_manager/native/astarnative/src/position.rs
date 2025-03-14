use rustler::NifMap;

#[derive(NifMap, Clone, Copy, Debug)]
pub struct Position {
    pub(crate) x: f32,
    pub(crate) y: f32,
}

impl Position {
    pub fn normalize(&mut self) {
        let length = (self.x.powi(2) + self.y.powi(2)).sqrt();
        self.x /= length;
        self.y /= length;
    }

    pub fn add(a: &Position, b: &Position) -> Position {
        Position {
            x: a.x + b.x,
            y: a.y + b.y,
        }
    }
    pub fn sub(a: &Position, b: &Position) -> Position {
        Position {
            x: a.x - b.x,
            y: a.y - b.y,
        }
    }

    pub fn mult(a: &Position, mult: f32) -> Position {
        Position {
            x: a.x * mult,
            y: a.y * mult,
        }
    }

    pub fn distance_to_position(&self, other_position: &Position) -> f32 {
        let x = self.x - other_position.x;
        let y = self.y - other_position.y;
        (x.powi(2) + y.powi(2)).sqrt()
    }
}

impl PartialEq for Position {
    fn eq(&self, other: &Position) -> bool {
        self.x == other.x && self.y == other.y
    }
}
impl Eq for Position {}
