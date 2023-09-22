use rustler::NifStruct;

#[derive(NifStruct, Clone)]
#[module = "LambdaGameEngine.MyrraEngine.Board"]
pub struct Board {
    pub width: usize,
    pub height: usize,
}
impl Board {
    pub fn new(width: usize, height: usize) -> Self {
        Self { width, height }
    }
}
