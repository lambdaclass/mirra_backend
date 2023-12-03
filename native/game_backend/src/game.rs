use std::collections::HashMap;

use rustler::NifMap;
use rustler::NifTaggedEnum;
use rustler::NifTuple;
use serde::Deserialize;

use crate::config::Config;
use crate::effect;
use crate::effect::Effect;
use crate::loot::Loot;
use crate::loot::PickupMechanic;
use crate::map;
use crate::map::Position;
use crate::player::Action;
use crate::player::Player;
use crate::player::PlayerStatus;
use crate::projectile::Projectile;
use crate::skill::SkillMechanic;

#[derive(Clone, Copy, Debug, Deserialize, NifTaggedEnum)]
pub enum GameError {
    CharacterNotFound,
}

#[derive(Clone, Copy, Debug, Deserialize, NifTaggedEnum)]
pub enum EntityOwner {
    Zone,
    Loot,
    Player(u64),
}

#[derive(Deserialize)]
pub struct GameConfigFile {
    width: u64,
    height: u64,
    loot_interval_ms: u64,
    zone_starting_radius: u64,
    zone_modifications: Vec<ZoneModificationConfigFile>,
    auto_aim_max_distance: f32,
    initial_positions: Vec<Position>,
}

#[derive(Deserialize)]
pub struct ZoneModificationConfigFile {
    duration_ms: u64,
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
    pub auto_aim_max_distance: f32,
    pub initial_positions: Vec<Position>,
}

#[derive(NifMap, Clone)]
pub struct ZoneModificationConfig {
    duration_ms: u64,
    interval_ms: u64,
    min_radius: u64,
    max_radius: u64,
    outside_radius_effects: Vec<Effect>,
    modification: ZoneModificationModifier,
}

#[derive(Deserialize, NifTaggedEnum, Clone)]
#[serde(tag = "modifier", content = "value")]
pub enum ZoneModificationModifier {
    Additive(i64),
    Multiplicative(f64),
}

#[derive(NifMap)]
pub struct Zone {
    pub center: Position,
    pub radius: u64,
    pub current_modification: Option<ZoneModificationConfig>,
    pub modifications: Vec<ZoneModificationConfig>,
    pub time_since_last_modification_ms: u64,
}

#[derive(Clone, Debug, NifTuple)]
pub struct KillEvent {
    pub kill_by: EntityOwner,
    pub killed: u64,
}

#[derive(NifMap)]
pub struct GameState {
    pub config: Config,
    pub players: HashMap<u64, Player>,
    pub loots: Vec<Loot>,
    pub projectiles: Vec<Projectile>,
    pub next_killfeed: Vec<KillEvent>,
    pub killfeed: Vec<KillEvent>,
    pub zone: Zone,
    next_id: u64,
}

impl GameConfig {
    pub(crate) fn from_config_file(game_config: GameConfigFile, effects: &[Effect]) -> GameConfig {
        let zone_modifications = game_config
            .zone_modifications
            .iter()
            .map(|zone_modification| {
                let outside_effects =
                    find_effects(&zone_modification.outside_radius_effects, effects);
                ZoneModificationConfig {
                    duration_ms: zone_modification.duration_ms,
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
            auto_aim_max_distance: game_config.auto_aim_max_distance,
            initial_positions: game_config.initial_positions,
        }
    }
}

impl GameState {
    pub fn new(config: Config) -> Self {
        let zone_radius = config.game.zone_starting_radius;
        let zone_modifications = config.game.zone_modifications.clone();
        let game_width = config.game.width;
        let game_height = config.game.height;

        Self {
            config,
            players: HashMap::new(),
            loots: Vec::new(),
            projectiles: Vec::new(),
            zone: Zone {
                center: Position { x: 0, y: 0 }, //map::random_position(game_width, game_height),
                radius: zone_radius,
                modifications: zone_modifications,
                current_modification: None,
                time_since_last_modification_ms: 0,
            },
            next_killfeed: Vec::new(),
            killfeed: Vec::new(),
            next_id: 1,
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

    pub fn move_player(&mut self, player_id: u64, angle: f32) {
        let players = &mut self.players;
        let loots = &mut self.loots;
        if let Some(player) = players.get_mut(&player_id) {
            if player.action_duration_ms > 0 {
                return;
            }
            player.move_position(angle, &self.config);
            collect_nearby_loot(loots, player);
        }
    }

    fn activate_skills(&mut self) {
        self.players.values_mut().for_each(|player| {
            let skill_keys = player.skills_keys_to_execute.clone();
            skill_keys.iter().for_each(|skill_key: &String| {
                if let Some(skill) = player.character.clone().skills.get(skill_key) {
                    player.add_action(
                        Action::UsingSkill(skill_key.to_string()),
                        skill.execution_duration_ms,
                    );

                    for mechanic in skill.mechanics.iter() {
                        match mechanic {
                            SkillMechanic::SimpleShoot {
                                projectile: projectile_config,
                            } => {
                                let id = get_next_id(&mut self.next_id);

                                let projectile = Projectile::new(
                                    id,
                                    player.position,
                                    player.direction,
                                    player.id,
                                    projectile_config,
                                );
                                self.projectiles.push(projectile);
                            }
                            _ => todo!("SkillMechanic not implemented"),
                        }
                    }
                }
            })
        });
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
            .filter(|player| player.status == PlayerStatus::Alive)
            .partition(|player| player.id == player_id);

        if let Some(player) = player_in_list.get_mut(0) {
            // Check if player is still performing an action
            if player.action_duration_ms > 0 {
                return;
            }

            // Check if skill is still on cooldown
            if player.cooldowns.contains_key(&skill_key) {
                return;
            }

            if let Some(skill) = player.character.clone().skills.get(&skill_key) {
                player.add_action(
                    Action::UsingSkill(skill_key.clone()),
                    skill.execution_duration_ms,
                );
                player.add_cooldown(&skill_key, skill.cooldown_ms);

                let auto_aim = skill_params
                    .get("auto_aim")
                    .map(|auto_aim_str| auto_aim_str.parse::<bool>().unwrap())
                    .unwrap();

                let direction_angle = if auto_aim {
                    let nearest_player: Option<Position> = nearest_player_position(
                        &other_players,
                        &player.position,
                        self.config.game.auto_aim_max_distance,
                    );

                    if let Some(target_player_position) = nearest_player {
                        map::angle_between_positions(&player.position, &target_player_position)
                    } else {
                        player.direction
                    }
                } else {
                    skill_params
                        .get("direction_angle")
                        .map(|angle_str| angle_str.parse::<f32>().unwrap())
                        .unwrap()
                };

                player.direction = direction_angle;

                for mechanic in skill.mechanics.iter() {
                    match mechanic {
                        SkillMechanic::SimpleShoot {
                            projectile: projectile_config,
                        } => {
                            let id = get_next_id(&mut self.next_id);

                            let projectile = Projectile::new(
                                id,
                                player.position,
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
                            let direction_distribution =
                                distribute_angle(direction_angle, cone_angle, count);
                            for direction in direction_distribution {
                                let id = get_next_id(&mut self.next_id);
                                let projectile = Projectile::new(
                                    id,
                                    player.position,
                                    direction,
                                    player.id,
                                    projectile_config,
                                );
                                self.projectiles.push(projectile);
                            }
                        }
                        SkillMechanic::GiveEffect { effects_to_give } => {
                            for effect in effects_to_give.iter() {
                                player.apply_effect(effect, EntityOwner::Player(player.id));
                            }
                        }
                        SkillMechanic::Hit {
                            damage,
                            range,
                            cone_angle,
                            on_hit_effects,
                        } => {
                            let mut damage = *damage;

                            for (effect, _owner) in player.effects.iter() {
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

                                    if target_player.status == PlayerStatus::Death {
                                        self.next_killfeed.push(KillEvent {
                                            kill_by: EntityOwner::Player(player.id),
                                            killed: target_player.id,
                                        })
                                    } else {
                                        target_player.apply_effects(
                                            on_hit_effects,
                                            EntityOwner::Player(player.id),
                                        );
                                    }
                                })
                        }
                        _ => todo!("SkillMechanic not implemented"),
                    }
                }
            }
        }
    }

    pub fn activate_inventory(&mut self, player_id: u64, inventory_at: usize) {
        if let Some(player) = self.players.get_mut(&player_id) {
            if let Some(loot) = player.inventory_take_at(inventory_at) {
                player.apply_effects(&loot.effects, EntityOwner::Loot)
            }
        }
    }

    pub fn tick(&mut self, time_diff: u64) {
        update_player_actions(&mut self.players, time_diff);
        self.activate_skills();
        update_player_cooldowns(&mut self.players, time_diff);
        move_projectiles(&mut self.projectiles, time_diff, &self.config);
        apply_projectiles_collisions(
            &mut self.projectiles,
            &mut self.players,
            &mut self.next_killfeed,
        );
        remove_expired_effects(&mut self.players);
        run_effects(&mut self.players, time_diff, &mut self.next_killfeed);
        modify_zone(&mut self.zone, time_diff);
        apply_zone_effects(&mut self.players, &self.zone, &mut self.next_killfeed);

        self.killfeed = self.next_killfeed.clone();
        self.next_killfeed.clear();
        update_kill_counts(&mut self.players, &self.killfeed);
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
            match loot.pickup_mechanic {
                PickupMechanic::CollisionToInventory => !player.put_in_inventory(loot),
                PickupMechanic::CollisionUse => {
                    player.apply_effects(&loot.effects, EntityOwner::Loot);
                    false
                }
            }
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

fn update_kill_counts(players: &mut HashMap<u64, Player>, killfeed: &[KillEvent]) {
    killfeed.iter().for_each(|kill_event| {
        if let EntityOwner::Player(player_id) = kill_event.kill_by {
            if let Some(player) = players.get_mut(&player_id) {
                player.add_kill();
            }
        }
    })
}

fn update_player_cooldowns(players: &mut HashMap<u64, Player>, elapsed_time_ms: u64) {
    players.values_mut().for_each(|player| {
        player.reduce_cooldowns(elapsed_time_ms);
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
        )
    });
}

fn apply_projectiles_collisions(
    projectiles: &mut [Projectile],
    players: &mut HashMap<u64, Player>,
    next_killfeed: &mut Vec<KillEvent>,
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
                if player.status == PlayerStatus::Death {
                    next_killfeed.push(KillEvent {
                        kill_by: EntityOwner::Player(projectile.player_id),
                        killed: player.id,
                    });
                }
                player.apply_effects(
                    &projectile.on_hit_effects,
                    EntityOwner::Player(projectile.player_id),
                );

                projectile.attacked_player_ids.push(player.id);
                if projectile.remove_on_collision {
                    projectile.active = false;
                }
                break;
            }
        }
    });
}

fn run_effects(
    players: &mut HashMap<u64, Player>,
    time_diff: u64,
    next_killfeed: &mut Vec<KillEvent>,
) {
    players.values_mut().for_each(|player| {
        if player.status == PlayerStatus::Alive {
            if let Some(killer) = player.run_effects(time_diff) {
                next_killfeed.push(KillEvent {
                    kill_by: killer,
                    killed: player.id,
                })
            }
        }
    });
}

fn remove_expired_effects(players: &mut HashMap<u64, Player>) {
    players
        .values_mut()
        .for_each(|player| player.remove_expired_effects());
}

fn modify_zone(zone: &mut Zone, time_diff: u64) {
    match &mut zone.current_modification {
        Some(zone_modification) if zone_modification.duration_ms > 0 => {
            zone_modification.duration_ms = zone_modification.duration_ms.saturating_sub(time_diff);
            zone.time_since_last_modification_ms += time_diff;

            if zone.time_since_last_modification_ms >= zone_modification.interval_ms {
                zone.time_since_last_modification_ms -= zone_modification.interval_ms;

                let new_radius = match zone_modification.modification {
                    ZoneModificationModifier::Additive(value) => {
                        zone.radius.saturating_add_signed(value)
                    }
                    ZoneModificationModifier::Multiplicative(value) => {
                        ((zone.radius as f64) * value) as u64
                    }
                };

                zone.radius = new_radius
                    .max(zone_modification.min_radius)
                    .min(zone_modification.max_radius);
            }
        }
        _ => {
            // Ideally we should be able to use a VecDeque::pop_first(), but rustler does not have
            // a encoder/decoder for it and at the moment I'm not implementing one
            if zone.modifications.is_empty() {
                zone.current_modification = None;
            } else {
                zone.current_modification = Some(zone.modifications.remove(0));
            }
        }
    }
}

fn apply_zone_effects(
    players: &mut HashMap<u64, Player>,
    zone: &Zone,
    next_killfeed: &mut Vec<KillEvent>,
) {
    // next_killfeed
    if let Some(current_modification) = &zone.current_modification {
        let (inside_players, outside_players): (Vec<_>, Vec<_>) = players
            .values_mut()
            // We set size of player as 0 so a player has to be half way inside the zone to be considered inside
            // otherwise if just a border of the player where inside it would be considered inside which seems wrong
            .partition(|player| {
                map::hit_boxes_collide(&zone.center, &player.position, zone.radius, 0)
            });

        inside_players.into_iter().for_each(|player| {
            for effect in current_modification.outside_radius_effects.iter() {
                player.remove_effect(&effect.name)
            }
        });

        outside_players.into_iter().for_each(|player| {
            // If the player is alive in this tick, but dies as an effect of the zone, we push it to the killfeed.
            if player.status == PlayerStatus::Alive {
                player.apply_effects_if_not_present(
                    &current_modification.outside_radius_effects,
                    EntityOwner::Zone,
                );
                if player.status == PlayerStatus::Death {
                    next_killfeed.push(KillEvent {
                        kill_by: EntityOwner::Zone,
                        killed: player.id,
                    });
                }
            }
        });
    }
}

fn nearest_player_position(
    players: &Vec<&mut Player>,
    position: &Position,
    max_search_distance: f32,
) -> Option<Position> {
    let mut nearest_player = None;
    let mut nearest_distance = max_search_distance;

    for player in players {
        if matches!(player.status, PlayerStatus::Alive) {
            let distance = map::distance_between_positions(&player.position, position);
            if distance < nearest_distance {
                nearest_player = Some(player.position);
                nearest_distance = distance;
            }
        }
    }
    nearest_player
}
