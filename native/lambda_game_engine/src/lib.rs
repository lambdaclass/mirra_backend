mod config;
mod effect;
mod loot;
mod projectile;
mod character;
mod skill;

use crate::config::Config;

#[rustler::nif]
fn parse_config(data: String) -> Config {
    config::parse_config(&data)
}

rustler::init!("Elixir.LambdaGameEngine", [parse_config]);
