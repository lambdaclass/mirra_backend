use std::collections::HashMap;

use rustler::NifMap;
use rustler::NifTaggedEnum;
use serde::Deserialize;

use crate::config::Config;
use crate::effect;
use crate::effect::Effect;
use crate::loot::Loot;
use crate::map;
use crate::player::Action;
use crate::player::Player;
use crate::player::PlayerStatus;
use crate::projectile::Projectile;
use crate::skill::SkillMechanic;

#[derive(Deserialize)]
pub struct GameConfigFile {
    width: u64,
    height: u64,
    loot_interval_ms: u64,
    zone_starting_radius: u64,
    zone_modifications: Vec<ZoneModificationConfigFile>,
}

#[derive(Deserialize)]
pub struct ZoneModificationConfigFile {
    duration_ms: u64,
    recenter_on_first_modification: bool,
    interval_ms: u64,
    min_radius: u64,
    max_radius: u64,
    outside_radius_effects: Vec<String>,
    modification: ZoneModificationModifier,
}

#[derive(NifMap)]
pub struct GameConfig {
    pub width: u64,
    pub height: u64,
    pub loot_interval_ms: u64,
    pub zone_starting_radius: u64,
    pub zone_modifications: Vec<ZoneModificationConfig>,
}

#[derive(NifMap)]
pub struct ZoneModificationConfig {
    duration_ms: u64,
    recenter_on_first_modification: bool,
    interval_ms: u64,
    min_radius: u64,
    max_radius: u64,
    outside_radius_effects: Vec<Effect>,
    modification: ZoneModificationModifier,
}

#[derive(Deserialize, NifTaggedEnum, Clone)]
#[serde(tag = "modifier", content = "value")]
pub enum ZoneModificationModifier {
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
        let zone_modifications = game_config.zone_modifications
            .iter()
            .map(|zone_modification| {
                let outside_effects = find_effects(&zone_modification.outside_radius_effects, effects);
                ZoneModificationConfig {
                    duration_ms: zone_modification.duration_ms,
                    recenter_on_first_modification: zone_modification.recenter_on_first_modification,
                    interval_ms: zone_modification.interval_ms,
                    min_radius: zone_modification.min_radius,
                    max_radius: zone_modification.max_radius,
                    modification: zone_modification.modification.clone(),
                    outside_radius_effects: outside_effects,
                }
            })
            .collect();

        GameConfig {
            width: game_config.width,
            height: game_config.height,
            loot_interval_ms: game_config.loot_interval_ms,
            zone_starting_radius: game_config.zone_starting_radius,
            zone_modifications,
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
        let (mut player_in_list, mut other_players): (Vec<_>, Vec<_>) = players
            .values_mut()
            .partition(|player| player.id == player_id);

        if let Some(player) = player_in_list.get_mut(0) {
            // Check if player is still performing an action
            if player.action_duration_ms > 0 {
                return;
            }

            if let Some(skill) = player.character.clone().skills.get(&skill_key) {
                player.add_action(Action::UsingSkill(skill_key), skill.execution_duration_ms);

                for mechanic in skill.mechanics.iter() {
                    match mechanic {
                        SkillMechanic::SimpleShoot {
                            projectile: projectile_config,
                        } => {
                            let id = get_next_id(&mut self.next_id);
                            let direction_angle = skill_params
                                .get("direction_angle")
                                .map(|angle_str| angle_str.parse::<f32>().unwrap())
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
                                .map(|angle_str| angle_str.parse::<f32>().unwrap())
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
                        SkillMechanic::Hit {
                            damage,
                            range,
                            cone_angle,
                            on_hit_effects,
                        } => {
                            let mut damage = *damage;

                            for effect in player.effects.iter() {
                                for change in effect.player_attributes.iter() {
                                    if change.attribute == "damage" {
                                        effect::modify_attribute(&mut damage, change)
                                    }
                                }
                            }

                            other_players
                                .iter_mut()
                                .filter(|target_player| {
                                    map::in_cone_angle_range(
                                        player,
                                        target_player,
                                        *range,
                                        *cone_angle as f32,
                                    )
                                })
                                .for_each(|target_player| {
                                    target_player.decrease_health(damage);
                                    target_player.apply_effects(on_hit_effects);
                                })
                        }
                        _ => todo!("SkillMechanic not implemented"),
                    }
                }
            }
        }
    }

    pub fn tick(&mut self, time_diff: u64) {
        update_player_actions(&mut self.players, time_diff);
        move_projectiles(&mut self.projectiles, time_diff, &self.config);
        apply_projectiles_collisions(&mut self.projectiles, &mut self.players);
        remove_expired_effects(&mut self.players);
        run_effects(&mut self.players, time_diff);
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

fn update_player_actions(players: &mut HashMap<u64, Player>, elapsed_time_ms: u64) {
    players.values_mut().for_each(|player| {
        player.update_actions();
        player.action_duration_ms = player.action_duration_ms.saturating_sub(elapsed_time_ms);
    })
}

fn move_projectiles(projectiles: &mut Vec<Projectile>, time_diff: u64, config: &Config) {
    // Clear out projectiles that are no longer valid
    projectiles.retain(|projectile| {
        projectile.active
            && projectile.duration_ms > 0
            && projectile.max_distance > 0
            && !map::collision_with_edge(
                &projectile.position,
                projectile.size,
                config.game.width,
                config.game.height,
            )
    });

    projectiles.iter_mut().for_each(|projectile| {
        projectile.duration_ms = projectile.duration_ms.saturating_sub(time_diff);
        projectile.max_distance = projectile.max_distance.saturating_sub(projectile.speed);
        projectile.position = map::next_position(
            &projectile.position,
            projectile.direction_angle,
            projectile.speed as f32,
            config.game.width as f32,
            config.game.height as f32,
        )
    });
}

fn apply_projectiles_collisions(
    projectiles: &mut [Projectile],
    players: &mut HashMap<u64, Player>,
) {
    projectiles.iter_mut().for_each(|projectile| {
        for player in players.values_mut() {
            if player.status == PlayerStatus::Alive
                && !projectile.attacked_player_ids.contains(&player.id)
                && map::hit_boxes_collide(
                    &projectile.position,
                    &player.position,
                    projectile.size,
                    player.size,
                )
            {
                if player.id == projectile.player_id {
                    continue;
                }

                player.decrease_health(projectile.damage);
                player.apply_effects(&projectile.on_hit_effects);
                projectile.attacked_player_ids.push(player.id);

                if projectile.remove_on_collision {
                    projectile.active = false;
                }
                break;
            }
        }
    });
}

fn run_effects(players: &mut HashMap<u64, Player>, time_diff: u64) {
    players
        .values_mut()
        .for_each(|player| player.run_effects(time_diff))
}

fn remove_expired_effects(players: &mut HashMap<u64, Player>) {
    players
        .values_mut()
        .for_each(|player| player.remove_expired_effects())
}
