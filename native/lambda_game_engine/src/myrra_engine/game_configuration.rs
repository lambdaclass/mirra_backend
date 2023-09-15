use rustler::Binary;
use std::collections::HashMap;

pub fn config_binaries_to_strings(
    binary_config: Vec<HashMap<Binary, Binary>>,
) -> Vec<HashMap<String, String>> {
    let mut string_config: Vec<HashMap<String, String>> = vec![];

    for binary_map in binary_config {
        let mut string_map: HashMap<String, String> = HashMap::new();
        for (key, val) in binary_map {
            // A rustler binary derefs into [u8], see:
            // https://docs.rs/rustler/latest/rustler/types/binary/struct.Binary.html
            let key = String::from_utf8((*key).to_vec())
                .expect("Could not parse {key} into a Rust string!");
            let val = String::from_utf8((*val).to_vec())
                .expect("Could not parse {val} into a Rust string!");
            string_map.insert(key, val);
        }
        string_config.push(string_map);
    }

    string_config
}
