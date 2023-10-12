use std::collections::HashMap;

use rustler::NifMap;
use rustler::NifTaggedEnum;
use serde::Deserialize;

use crate::config::Config;
use crate::effect::Effect;
use crate::loot::Loot;
use crate::map;
use crate::player::Player;
use crate::projectile::Projectile;
use crate::skill::SkillMechanic;

#[derive(Deserialize)]
pub struct GameConfigFile {
    width: u64,
    height: u64,
    loot_interval_ms: u64,
    map_modification: MapModificationConfigFile,
}

#[derive(Deserialize)]
pub struct MapModificationConfigFile {
    starting_radius: u64,
    minimum_radius: u64,
    max_radius: u64,
    outside_radius_effects: Vec<String>,
    inside_radius_effects: Vec<String>,
    modification: MapModificationModifier,
}

#[derive(NifMap)]
pub struct GameConfig {
    pub width: u64,
    pub height: u64,
    pub loot_interval_ms: u64,
    pub map_modification: MapModificationConfig,
}

#[derive(NifMap)]
pub struct MapModificationConfig {
    starting_radius: u64,
    minimum_radius: u64,
    max_radius: u64,
    outside_radius_effects: Vec<Effect>,
    inside_radius_effects: Vec<Effect>,
    modification: MapModificationModifier,
}

#[derive(Deserialize, NifTaggedEnum)]
#[serde(tag = "modifier", content = "value")]
pub enum MapModificationModifier {
    Additive(u64),
    Multiplicative(f64),
}

#[derive(NifMap)]
pub struct GameState {
    pub config: Config,
    pub players: HashMap<u64, Player>,
    pub loots: Vec<Loot>,
    pub projectiles: Vec<Projectile>,
    pub myrra_state: crate::myrra_engine::game::GameState,
    next_id: u64,
}

impl GameConfig {
    pub(crate) fn from_config_file(game_config: GameConfigFile, effects: &[Effect]) -> GameConfig {
        let outside_effects = find_effects(
            &game_config.map_modification.outside_radius_effects,
            effects,
        );
        let inside_effects =
            find_effects(&game_config.map_modification.inside_radius_effects, effects);

        GameConfig {
            width: game_config.width,
            height: game_config.height,
            loot_interval_ms: game_config.loot_interval_ms,
            map_modification: MapModificationConfig {
                starting_radius: game_config.map_modification.starting_radius,
                minimum_radius: game_config.map_modification.minimum_radius,
                max_radius: game_config.map_modification.max_radius,
                outside_radius_effects: outside_effects,
                inside_radius_effects: inside_effects,
                modification: game_config.map_modification.modification,
            },
        }
    }
}

impl GameState {
    pub fn new(config: Config) -> Self {
        Self {
            config,
            players: HashMap::new(),
            loots: Vec::new(),
            projectiles: Vec::new(),
            next_id: 1,
            myrra_state: crate::myrra_engine::game::GameState::placeholder_new(),
        }
    }

    pub fn next_id(&mut self) -> u64 {
        get_next_id(&mut self.next_id)
    }

    pub fn push_player(&mut self, player_id: u64, player: Player) {
        self.players.insert(player_id, player);
    }

    pub fn push_loot(&mut self, loot: Loot) {
        self.loots.push(loot);
    }

    pub fn update_myrra_state(&mut self, myrra_state: crate::myrra_engine::game::GameState) {
        self.myrra_state = myrra_state;
    }

    pub fn move_player(&mut self, player_id: u64, angle: f32) {
        let players = &mut self.players;
        let loots = &mut self.loots;
        if let Some(player) = players.get_mut(&player_id) {
            player.move_position(angle, &self.config);
            collect_nearby_loot(loots, player);
        }
    }

    pub fn activate_skill(
        &mut self,
        player_id: u64,
        skill_key: String,
        skill_params: HashMap<String, String>,
    ) {
        let players = &mut self.players;
        // let (players, _other_players): (Vec<Player>, Vec<Player>) = players.into_values().partition(|player| player.id == player_id);

        if let Some(player) = players.get_mut(&player_id) {
            if let Some(skill) = player.character.clone().skills.get(&skill_key) {
                for mechanic in skill.mechanics.iter() {
                    match mechanic {
                        SkillMechanic::SimpleShoot {
                            projectile: projectile_config,
                        } => {
                            let id = get_next_id(&mut self.next_id);
                            let direction_angle = skill_params
                                .get("direction_angle")
                                .map(|angle_str| angle_str.parse::<f32>())
                                .unwrap()
                                .unwrap();
                            let projectile = Projectile::new(
                                id,
                                player.position.clone(),
                                direction_angle,
                                player.id,
                                projectile_config,
                            );
                            self.projectiles.push(projectile);
                        }
                        SkillMechanic::MultiShoot {
                            projectile: projectile_config,
                            count,
                            cone_angle,
                        } => {
                            let direction_angle = skill_params
                                .get("direction_angle")
                                .map(|angle_str| angle_str.parse::<f32>())
                                .unwrap()
                                .unwrap();
                            let direction_distribution =
                                distribute_angle(direction_angle, cone_angle, count);
                            for direction in direction_distribution {
                                let id = get_next_id(&mut self.next_id);
                                let projectile = Projectile::new(
                                    id,
                                    player.position.clone(),
                                    direction,
                                    player.id,
                                    projectile_config,
                                );
                                self.projectiles.push(projectile);
                            }
                        }
                        SkillMechanic::GiveEffect(effects) => {
                            for effect in effects.iter() {
                                player.apply_effect(effect);
                            }
                        }
                        _ => todo!("SkillMechanic not implemented"),
                    }
                }
            }
        }
    }

    pub fn tick(&mut self, time_diff: u64) {
        move_projectiles(&mut self.projectiles, time_diff, &self.config);
    }
}

fn find_effects(config_effects_names: &[String], effects: &[Effect]) -> Vec<Effect> {
    config_effects_names
        .iter()
        .map(|config_effect_name| {
            effects
                .iter()
                .find(|effect| *config_effect_name == effect.name)
                .unwrap_or_else(|| {
                    panic!(
                        "Game map_modification effect `{}` does not exist in effects config",
                        config_effect_name
                    )
                })
                .clone()
        })
        .collect()
}

fn get_next_id(next_id: &mut u64) -> u64 {
    let id = *next_id;
    *next_id += 1;
    id
}

fn collect_nearby_loot(loots: &mut Vec<Loot>, player: &mut Player) {
    loots.retain(|loot| {
        if map::hit_boxes_collide(&loot.position, &player.position, loot.size, player.size) {
            loot.effects
                .iter()
                .for_each(|effect| player.apply_effect(effect));
            false
        } else {
            true
        }
    });
}

fn distribute_angle(direction_angle: f32, cone_angle: &u64, count: &u64) -> Vec<f32> {
    let mut angles = Vec::new();
    let half_cone_angle = cone_angle / 2;
    let half_count = count / 2;
    let cone_angle_diff = half_cone_angle / count;

    // Generate the top angles
    for i in 1..=half_count {
        let angle = direction_angle + (cone_angle_diff * i) as f32;
        angles.push(angle);
    }

    // Add the base angle if we have an odd count
    if count % 2 != 0 {
        angles.push(direction_angle);
    }

    // Generate the bottom angles
    for i in 1..=half_count {
        let angle = direction_angle - (cone_angle_diff * i) as f32;
        angles.push(angle);
    }

    angles
}

fn move_projectiles(projectiles: &mut Vec<Projectile>, time_diff: u64, config: &Config) {
    projectiles.retain(|projectile| projectile.duration_ms > 0 && projectile.max_distance > 0);
    projectiles
    .iter_mut()
    .for_each(|projectile| {
        projectile.duration_ms = projectile.duration_ms - time_diff;
        projectile.position = map::next_position(&projectile.position, projectile.direction_angle, projectile.speed as f32, config.game.width as f32, config.game.height as f32)
    });
}
