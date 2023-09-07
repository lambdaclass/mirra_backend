mod config;
mod effect;

use crate::config::Config;

#[rustler::nif]
fn parse_config(data: String) -> Config {
    config::parse_config(&data)
}

rustler::init!("Elixir.LambdaGameEngine", [parse_config]);
