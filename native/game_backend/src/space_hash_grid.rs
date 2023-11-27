use std::collections::HashMap;
use std::cell::RefCell;

/// bounds = grid limits 
/// dimensions = cell dimension
pub struct SpatialHashGrid {
    bounds: [(isize, isize); 2],
    dimensions: (isize, isize),
    cells: HashMap<(isize, isize), isize>
}

#[derive(Clone)]
pub struct HashGridClient {
    position: (isize, isize),
    dimensions: (isize, isize),
    indices: Option<[(isize, isize); 2]>
}

pub type Client = RefCell<HashGridClient>; 

impl SpatialHashGrid {
    pub fn new(bounds: [(isize, isize); 2], dimensions: (isize, isize)) -> Self {
        let cells = HashMap::new();
        SpatialHashGrid {
            bounds,
            dimensions,
            cells
        } 
    }
    pub fn new_client(&mut self, position: (isize, isize), dimensions: (isize, isize)) -> Client {
       let client: Client = RefCell::new( HashGridClient { position, dimensions, indices: None});
        self.insert_client(client.clone());
        return client;
    }
    
    pub fn insert_client(&mut self, client: Client) {
        let mut client = client.borrow_mut();
        let (x, y) = client.position;
        let (w, h) = client.dimensions;
        let i1 = self.get_cell_index((x-w / 2, y + h / 2));
        let i2 = self.get_cell_index((x+w / 2, y + h / 2));
        client.indices = Some([i1, i2]);
    }

    pub fn get_cell_index(&self, (p1, p2): (isize, isize)) -> (isize, isize)  {
        let x = sat((p1 - self.bounds[0].0) / (self.bounds[1].0) - self.bounds[0].1);
        let y = sat((p2 - self.bounds[0].0) / (self.bounds[1].1) - self.bounds[0].1);

        let x_index = x*(self.dimensions.0-1);
        let y_index = y*(self.dimensions.1-1);
        return (x_index, y_index)
    }
}

fn sat(x: isize) -> isize {
    isize::min(isize::max(x, 0), 1)
}
