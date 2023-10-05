use super::board::Board;
use super::character::{Character, Name};
use super::loot::{self, Loot, LootType};
use super::player::{Effect, EffectData, Player, PlayerAction, Position, Status};
use super::projectile::{Projectile, ProjectileStatus, ProjectileType};
use super::skills::{self, Skill};
use super::time_utils::{
    add_millis, millis_to_u128, sub_millis, time_now, u128_to_millis, MillisTime,
};
use super::utils::{self, angle_between_vectors, cmp_float, RelativePosition};
use itertools::Itertools;
use rand::{thread_rng, Rng};
use rustler::{NifStruct, NifTuple, NifUnitEnum};
use std::f32::consts::PI;

use std::cmp::{max, min};
use std::collections::HashMap;
use std::collections::HashSet;

#[derive(NifStruct, Clone)]
#[module = "LambdaGameEngine.MyrraEngine.Game"]
pub struct GameState {
    pub players: Vec<Player>,
    pub board: Board,
    pub next_killfeed: Vec<KillEvent>,
    pub killfeed: Vec<KillEvent>,
    pub projectiles: Vec<Projectile>,
    pub next_projectile_id: u64,
    pub playable_radius: u64,
    pub shrinking_center: Position,
    pub loots: Vec<Loot>,
    pub next_loot_id: u64,
}

#[derive(Clone, NifTuple)]
pub struct KillEvent {
    pub kill_by: u64,
    pub killed: u64,
}

#[derive(Debug, NifUnitEnum)]
pub enum Direction {
    UP,
    DOWN,
    LEFT,
    RIGHT,
}

impl GameState {
    fn build_characters_with_config(
        character_config: &[HashMap<String, String>],
        skills: &[Skill],
    ) -> Result<Vec<Character>, String> {
        character_config
            .into_iter()
            // Keep only characters
            // for which active is 1.
            .filter(|map| {
                let active = map
                    .get("Active")
                    .expect("Missing Active key for character")
                    .parse::<u64>()
                    .expect("Expected 1 or 0 for Active key");
                active == 1
            })
            .map(|config| Character::from_config_map(config, skills))
            .collect()
    }

    pub fn placeholder_new() -> Self {
        Self {
            players: Vec::new(),
            board: Board::new(10, 10),
            next_killfeed: Vec::new(),
            killfeed: Vec::new(),
            projectiles: Vec::new(),
            next_projectile_id: 0,
            playable_radius: 0,
            shrinking_center: Position::new(0, 0),
            loots: Vec::new(),
            next_loot_id: 0,
        }
    }

    pub fn new(
        selected_characters: HashMap<u64, Name>,
        number_of_players: u64,
        board_width: usize,
        board_height: usize,
        _build_walls: bool,
        characters_config: &[HashMap<String, String>],
        skills_config: &[HashMap<String, String>],
    ) -> Result<Self, String> {
        let mut positions = HashSet::new();
        let skills = skills::build_from_config(skills_config)?;
        let characters = GameState::build_characters_with_config(&characters_config, &skills)?;
        let players: Vec<Player> = (1..number_of_players + 1)
            .map(|player_id| -> Result<Player, String> {
                let new_position = generate_new_position(&mut positions, board_width, board_height);

                let selected_character = selected_characters
                    .get(&player_id)
                    .ok_or(format!("Could not get player {player_id} character"))?;

                let character = characters
                    .iter()
                    .find(|x| x.name == *selected_character)
                    .ok_or("Can't get the character")?
                    .clone();

                Ok(Player::new(player_id, 100, new_position, character))
            })
            .collect::<Result<Vec<Player>, String>>()?;

        let board = Board::new(board_width, board_height);

        let rng = &mut thread_rng();
        let shrinking_center_x_coordinate: usize = rng.gen_range(0..board_width);
        let shrinking_center_y_coordinate: usize = rng.gen_range(0..board_height);
        let shrinking_center = Position {
            x: shrinking_center_x_coordinate,
            y: shrinking_center_y_coordinate,
        };

        let playable_radius = calculate_hypotenuse(board_width as u64, board_height as u64);
        Ok(Self {
            players,
            board,
            next_killfeed: Vec::new(),
            killfeed: Vec::new(),
            projectiles: Vec::new(),
            next_projectile_id: 0,
            playable_radius: playable_radius,
            shrinking_center,
            loots: Vec::new(),
            next_loot_id: 0,
        })
    }

    pub fn move_player(
        self: &mut Self,
        player_id: u64,
        direction: Direction,
    ) -> Result<(), String> {
        let player = self
            .players
            .iter_mut()
            .find(|player| player.id == player_id)
            .unwrap();

        if matches!(player.status, Status::DEAD) {
            return Ok(());
        }

        let mut new_position = compute_adjacent_position_n_tiles(
            &direction,
            &player.position,
            player.speed() as usize,
        );

        // These changes are done so that if the player is moving into one of the map's borders
        // but is not already on the edge, they move to the edge. In simpler terms, if the player is
        // trying to move from (0, 1) to the left, this ensures that new_position is (0, 0) instead of
        // something invalid like (0, -1).
        new_position.x = min(new_position.x, self.board.height - 1);
        new_position.x = max(new_position.x, 0);
        new_position.y = min(new_position.y, self.board.width - 1);
        new_position.y = max(new_position.y, 0);

        // let tile_to_move_to = tile_to_move_to(&self.board, &player.position, &new_position);

        player.position = new_position;

        Ok(())
    }

    pub fn _move_player_to_relative_position(
        board: &mut Board,
        attacking_player: &mut Player,
        direction: &RelativePosition,
    ) -> Result<(), String> {
        let new_position_coordinates = GameState::new_position(
            attacking_player.position,
            direction,
            board.height,
            board.width,
        );

        attacking_player.position = new_position_coordinates;

        Ok(())
    }

    pub fn new_position(
        initial_position: Position,
        direction: &RelativePosition,
        board_height: usize,
        board_width: usize,
    ) -> Position {
        // TODO: 120 should be a config. It's the realtion between front range in skills and
        // the distance in the back.
        let new_position_x = initial_position.x as i64 - (direction.y * 1200f32) as i64;
        let new_position_y = initial_position.y as i64 + (direction.x * 1200f32) as i64;

        // These changes are done so that if the player is moving into one of the map's borders
        // but is not already on the edge, they move to the edge. In simpler terms, if the player is
        // trying to move from (0, 1) to the left, this ensures that new_position is (0, 0) instead of
        // something invalid like (0, -1).

        let new_position_x = min(new_position_x, (board_height - 1).try_into().unwrap());
        let new_position_x = max(new_position_x, 0);
        let new_position_y = min(new_position_y, (board_width - 1).try_into().unwrap());
        let new_position_y = max(new_position_y, 0);

        Position {
            x: new_position_x as usize,
            y: new_position_y as usize,
        }
    }

    // Takes the raw value from Unity's joystick
    // and calculates the resulting position on the grid.
    // The joystick values are 2 floating point numbers,
    // x and y which are translated to the character's delta
    // into a certain grid direction. A conversion with rounding
    // to the nearest integer is done to obtain the grid coordinates.
    // The (x,y) input value becomes:
    // (-1*rounded_nearest_integer(y), round_nearest_integer(x)).
    // Eg: If the input is (-0.7069376, 0.7072759) (a left-upper joystick movement) the movement on the grid
    // becomes (-1, -1). Because the input is a left-upper joystick movement
    pub fn move_with_joystick(
        self: &mut Self,
        player_id: u64,
        x: f32,
        y: f32,
    ) -> Result<(), String> {
        let player = Self::get_player_mut(&mut self.players, player_id)?;
        if matches!(player.status, Status::DEAD) {
            return Ok(());
        }

        if !player.can_move() {
            return Ok(());
        }

        player.action = PlayerAction::MOVING;

        let direction = match player.has_active_effect(&Effect::DanseMacabre) {
            true => RelativePosition { x: y, y: -x },
            false => RelativePosition { x, y },
        };

        let speed = player.speed() as i64;

        GameState::move_player_to_direction(
            &mut self.board,
            &mut player.position,
            &direction,
            speed,
        )?;
        player.direction = direction;

        Self::find_and_apply_loots(&mut self.loots, player);

        Ok(())
    }

    pub fn move_player_to_direction(
        board: &mut Board,
        position: &mut Position,
        direction: &RelativePosition,
        speed: i64,
    ) -> Result<(), String> {
        let new_position = new_entity_position(
            board.height,
            board.width,
            direction.x,
            direction.y,
            *position,
            speed,
        );

        *position = new_position;

        Ok(())
    }

    pub fn get_player_mut(
        players: &mut Vec<Player>,
        player_id: u64,
    ) -> Result<&mut Player, String> {
        players
            .iter_mut()
            .find(|player| player.id == player_id)
            .ok_or(format!("Given id ({player_id}) is not valid"))
    }

    pub fn find_and_apply_loots(loots: &mut Vec<Loot>, player: &mut Player) {
        let (loot_hit, loot_miss): (Vec<Loot>, Vec<Loot>) = loots.iter().partition(|loot| {
            utils::hit_boxes_collide(
                player.position,
                loot.position,
                player.character.body_size,
                loot.size,
            )
        });
        for loot in loot_hit {
            match loot.loot_type {
                // Cap health to a max of 100
                LootType::Health(heal_amount) => {
                    player.health = min(player.health + heal_amount as i64, 100)
                }
            }
        }

        *loots = loot_miss;
    }

    pub fn get_player(players: &Vec<Player>, player_id: u64) -> Result<&Player, String> {
        players
            .get((player_id - 1) as usize)
            .ok_or(format!("Given id ({player_id}) is not valid"))
    }

    // Return all player_id in range and not dead
    pub fn players_in_range(
        players: &Vec<Player>,
        attacking_position: &Position,
        range: f64,
    ) -> Vec<(u64, f64)> {
        let mut players_in_range: Vec<(u64, f64)> = vec![];
        for player in players {
            let distance = distance_between_positions(&player.position, attacking_position);
            if distance <= range && !matches!(player.status, Status::DEAD) {
                players_in_range.push((player.id, distance));
            }
        }
        players_in_range
    }

    pub fn players_in_range_and_angle(
        players: &[Player],
        direction: &RelativePosition,
        attacking_position: &Position,
        range: f64,
        angle: u64,
    ) -> Vec<(u64, f64)> {
        let mut players_in_angle: Vec<(u64, f64)> = vec![];
        for player in players {
            let v1 = RelativePosition::new(
                player.position.y as f32 - attacking_position.y as f32,
                -(player.position.x as f32 - attacking_position.x as f32),
            );
            let angle_between_players = angle_between_vectors(v1, *direction);

            let distance = distance_between_positions(&player.position, attacking_position);
            if distance <= range
                && angle_between_players <= angle / 2
                && !matches!(player.status, Status::DEAD)
            {
                players_in_angle.push((player.id, distance));
            }
        }
        players_in_angle
    }

    pub fn players_in_projectile_movement(
        attacking_player_id: u64,
        players: &Vec<Player>,
        projectile_position: Position,
    ) -> HashMap<u64, f64> {
        let mut affected_players: HashMap<u64, f64> = HashMap::new();

        let attacking_player = GameState::get_player(players, attacking_player_id).unwrap();

        players
            .iter()
            .filter(|player| {
                matches!(player.status, Status::ALIVE) && player.id != attacking_player_id
            })
            .for_each(|player| {
                // We're intersecting two circles, basically what we're doing is this:
                // Sum the character's radius body size and the projectile's radius,
                // Calculate the distance between the centers of both circles (player's position and projectile's position)
                // And then we check if the sum of the radius is greater than the distance between
                // centers, then the projectile hitted the target :)
                let character_body_size = player.character.body_size;
                let projectile_radius = 10.;

                let centers_distance =
                    distance_between_positions(&projectile_position, &player.position);
                let radiuses_sum = character_body_size + projectile_radius;
                if radiuses_sum >= centers_distance {
                    affected_players.insert(
                        player.id,
                        distance_to_center(attacking_player, &player.position),
                    );
                }
            });

        affected_players
    }

    pub fn basic_attack(
        self: &mut Self,
        attacking_player_id: u64,
        direction: &RelativePosition,
    ) -> Result<(), String> {
        let players = &self.players.clone();
        let attacking_player = GameState::get_player_mut(&mut self.players, attacking_player_id)?;

        if !attacking_player.can_attack(attacking_player.basic_skill_cooldown_left, true) {
            return Ok(());
        }

        let now = time_now();
        attacking_player.action = PlayerAction::ATTACKING;
        attacking_player.basic_skill_started_at = now;
        attacking_player.basic_skill_cooldown_left = attacking_player.basic_skill_cooldown();
        attacking_player.basic_skill_ends_at =
            add_millis(now, attacking_player.basic_skill_cooldown_left);
        attacking_player.direction = *direction;
        let attack_range = attacking_player.basic_skill_range();
        let attack_angle = attacking_player.basic_skill_angle();

        let attacked_player_ids = match attacking_player.character.name {
            Name::H4ck => Self::h4ck_basic_attack(
                attacking_player,
                direction,
                &mut self.projectiles,
                &mut self.next_projectile_id,
            ),
            Name::Muflus => {
                let attacking_player = GameState::get_player(players, attacking_player_id)?;
                let extra_effect = GameState::get_extra_effect(attacking_player, now);
                self.melee_attack(
                    attacking_player,
                    direction,
                    attack_range,
                    attack_angle,
                    extra_effect,
                )
            }
            Name::DAgna => Self::dagna_basic_attack(attacking_player),
            Name::Uma => {
                let players = &self.players.clone();
                let attacking_player = GameState::get_player(players, attacking_player_id)?;

                let attacked_players_ids = self.melee_attack(
                    attacking_player,
                    direction,
                    attack_range,
                    attack_angle,
                    None,
                )?;
                for attacked_player_id in attacked_players_ids.clone() {
                    let attacked_player =
                        GameState::get_player_mut(&mut self.players, attacked_player_id)?;
                    attacked_player.add_effect(
                        Effect::ElnarMark,
                        true,
                        EffectData {
                            time_left: attacking_player.character.duration_basic_skill(),
                            ends_at: add_millis(
                                now,
                                attacking_player.character.duration_basic_skill(),
                            ),
                            duration: attacking_player.character.duration_basic_skill(),
                            direction: None,
                            position: None,
                            triggered_at: now,
                            caused_by: attacking_player.id,
                            caused_to: attacked_player.id,
                            damage: 0,
                        },
                    );
                }
                Ok(attacked_players_ids)
            }
        };

        self.update_killfeed(attacking_player_id, attacked_player_ids?);
        Ok(())
    }

    pub fn get_extra_effect(
        attacking_player: &Player,
        now: MillisTime,
    ) -> Option<(Effect, EffectData)> {
        if attacking_player.has_active_effect(&Effect::FieryRampage) {
            let effect_data = EffectData {
                time_left: u128_to_millis(2000 as u128),
                ends_at: add_millis(now, u128_to_millis(2000 as u128)),
                duration: u128_to_millis(2000 as u128),
                direction: None,
                position: None,
                triggered_at: now,
                caused_by: attacking_player.id,
                caused_to: attacking_player.id,
                damage: attacking_player.basic_skill_damage() / 4,
            };
            return Some((Effect::Burned, effect_data));
        }
        None
    }

    pub fn h4ck_basic_attack(
        attacking_player: &mut Player,
        direction: &RelativePosition,
        projectiles: &mut Vec<Projectile>,
        next_projectile_id: &mut u64,
    ) -> Result<Vec<u64>, String> {
        if direction.x != 0f32 || direction.y != 0f32 {
            let piercing = attacking_player.has_active_effect(&Effect::DenialOfService);

            let angle = (direction.y as f32).atan2(direction.x as f32); // Calculates the angle in radians.
            let angle_positive = if angle < 0.0 {
                (angle + 2.0 * PI).to_degrees() // Adjusts the angle if negative.
            } else {
                angle.to_degrees()
            };

            let angle_modifiers = [-20f32, 0f32, 20f32];

            let mut speed = attacking_player.character.par_1_skill_1() as f32;
            if piercing {
                speed *= 1.25;
            }

            for modifier in angle_modifiers {
                let projectile = Projectile::new(
                    *next_projectile_id,
                    attacking_player.position,
                    RelativePosition::new(
                        (angle_positive + modifier).to_radians().cos(),
                        (angle_positive + modifier).to_radians().sin(),
                    ),
                    speed as u32,
                    1,
                    attacking_player.id,
                    attacking_player.skill_1_damage(),
                    30,
                    ProjectileType::BULLET,
                    ProjectileStatus::ACTIVE,
                    attacking_player.id,
                    piercing,
                    "SLINGSHOT".to_string(),
                );
                projectiles.push(projectile);
                (*next_projectile_id) += 1;
            }
        }
        Ok(Vec::new())
    }

    fn nearest_player(
        players: &Vec<Player>,
        position: &Position,
        direction: &RelativePosition,
        attacking_player_id: u64,
        max_distance: f64,
        max_angle: u64,
    ) -> Option<(u64, Position)> {
        let mut nearest_player = None;
        let mut nearest_distance = max_distance;
        let mut lowest_hp = 1000;

        for player in players {
            if player.id != attacking_player_id && matches!(player.status, Status::ALIVE) {
                let distance = distance_to_center(player, position);
                let v1 = direction;
                let v2 = RelativePosition::new(
                    player.position.y as f32 - position.y as f32,
                    -(player.position.x as f32 - position.x as f32),
                );
                let angle = angle_between_vectors(*v1, v2);
                if distance < nearest_distance
                    && angle < (max_angle / 2)
                    && player.health <= lowest_hp
                {
                    lowest_hp = player.health;
                    nearest_player = Some((player.id, player.position));
                    nearest_distance = distance;
                }
            }
        }
        nearest_player
    }

    pub fn melee_attack(
        self: &mut Self,
        attacking_player: &Player,
        direction: &RelativePosition,
        attack_range: f64,
        attack_angle: u64,
        effect: Option<(Effect, EffectData)>,
    ) -> Result<Vec<u64>, String> {
        let attack_dmg = attacking_player.basic_skill_damage() as i64;

        let (attacked_players, direction) = match Self::nearest_player(
            &mut self.players,
            &attacking_player.position,
            &attacking_player.direction,
            attacking_player.id,
            attack_range,
            attack_angle,
        ) {
            Some((player_id, position)) => {
                let direction = RelativePosition::new(
                    position.y as f32 - attacking_player.position.y as f32,
                    -(position.x as f32 - attacking_player.position.x as f32),
                );
                let mut uma_mirroring_affected_players: HashMap<u64, (i64, u64)> = HashMap::new();

                let attacked_player = GameState::get_player_mut(&mut self.players, player_id)?;

                attacked_player.modify_health(-attack_dmg);
                match attacked_player.get_mirrored_player_id() {
                    Some(mirrored_id) => uma_mirroring_affected_players
                        .insert(attacked_player.id, ((attack_dmg / 2), mirrored_id)),
                    None => None,
                };

                match effect {
                    Some((effect, effect_data)) => {
                        let mut effect_data = effect_data.clone();
                        effect_data.caused_to = attacked_player.id;
                        attacked_player.add_effect(effect, false, effect_data);
                    }
                    None => (),
                }

                self.attack_mirrored_player(uma_mirroring_affected_players)?;

                (vec![player_id], direction)
            }
            None => (Vec::new(), *direction),
        };

        let attacking_player = GameState::get_player_mut(&mut self.players, attacking_player.id)?;
        attacking_player.direction = direction;

        Ok(attacked_players)
    }

    pub fn dagna_basic_attack(attacking_player: &mut Player) -> Result<Vec<u64>, String> {
        match attacking_player.effects.get(&Effect::Scherzo) {
            Some(_) => {
                attacking_player.effects.remove(&Effect::Scherzo);
            }
            None => {
                let now = time_now();
                attacking_player.add_effect(
                    Effect::Scherzo.clone(),
                    false,
                    EffectData {
                        time_left: attacking_player.character.duration_basic_skill(),
                        ends_at: add_millis(now, attacking_player.character.duration_basic_skill()),
                        duration: attacking_player.character.duration_basic_skill(),
                        direction: None,
                        position: None,
                        triggered_at: u128_to_millis(0),
                        caused_by: attacking_player.id,
                        caused_to: attacking_player.id,
                        damage: attacking_player.character.attack_dmg_basic_skill(),
                    },
                );
            }
        }

        Ok(Vec::new())
    }

    pub fn skill_1(
        self: &mut Self,
        attacking_player_id: u64,
        direction: &RelativePosition,
    ) -> Result<(), String> {
        let pys = self.players.clone();
        let mut attacking_player =
            GameState::get_player_mut(&mut self.players, attacking_player_id)?;

        if !attacking_player.can_attack(attacking_player.skill_1_cooldown_left, false) {
            return Ok(());
        }

        let now = time_now();
        attacking_player.skill_1_started_at = now;
        attacking_player.skill_1_cooldown_left = attacking_player.skill_1_cooldown();
        attacking_player.skill_1_ends_at = add_millis(now, attacking_player.skill_1_cooldown_left);
        attacking_player.direction = *direction;
        attacking_player.action = PlayerAction::EXECUTINGSKILL1;
        let attack_angle = attacking_player.skill_1_angle();

        let attacked_player_ids = match attacking_player.character.name {
            Name::H4ck => Self::h4ck_skill_1(
                attacking_player,
                direction,
                &mut self.projectiles,
                &mut self.next_projectile_id,
            ),
            Name::Muflus => {
                let players = &mut self.players;
                Self::muflus_skill_1(players, attacking_player_id, now)
            }
            Name::DAgna => {
                // let players = &mut self.players;
                // Self::dagna_skill_1(players, attacking_player_id)
                Ok(Vec::new())
            }
            Name::Uma => {
                let attacking_player = GameState::get_player(&self.players, attacking_player_id)?;
                let attacking_player_id = attacking_player.id;
                let duration = attacking_player.character.duration_skill_1();
                let damage = attacking_player.skill_1_damage();

                let mut affected_players: Vec<u64> = GameState::players_in_range_and_angle(
                    &pys,
                    direction,
                    &attacking_player.position,
                    attacking_player.skill_1_range(),
                    attack_angle,
                )
                .into_iter()
                .filter(|&(id, _distance)| id != attacking_player_id)
                .map(|(player_id, _position)| player_id)
                .collect();

                for player_id in affected_players.iter_mut() {
                    let attacked_player: Option<&mut Player> = self
                        .players
                        .iter_mut()
                        .find(|player| player.id == *player_id && player.id != attacking_player_id);

                    match attacked_player {
                        Some(attacked_player) => {
                            attacked_player.add_effect(
                                Effect::YugenMark,
                                true,
                                EffectData {
                                    time_left: duration,
                                    ends_at: add_millis(now, duration),
                                    duration: duration,
                                    direction: None,
                                    position: None,
                                    triggered_at: now,
                                    caused_by: attacking_player_id,
                                    caused_to: attacked_player.id,
                                    damage: 0,
                                },
                            );
                            attacked_player.add_effect(
                                Effect::Poisoned,
                                true,
                                EffectData {
                                    time_left: duration,
                                    ends_at: add_millis(now, duration),
                                    duration: duration,
                                    direction: None,
                                    position: None,
                                    triggered_at: now,
                                    caused_by: attacking_player_id,
                                    caused_to: attacked_player.id,
                                    damage: damage,
                                },
                            );
                        }
                        _ => continue,
                    }
                }

                Ok(affected_players)
            }
        };

        self.update_killfeed(attacking_player_id, attacked_player_ids?);
        Ok(())
    }

    pub fn h4ck_skill_1(
        attacking_player: &mut Player,
        direction: &RelativePosition,
        projectiles: &mut Vec<Projectile>,
        next_projectile_id: &mut u64,
    ) -> Result<Vec<u64>, String> {
        if !attacking_player.can_attack(attacking_player.skill_3_cooldown_left, false) {
            return Ok(Vec::new());
        }

        if attacking_player.has_active_effect(&Effect::Paralyzed)
            && (attacking_player.character.name == Name::H4ck
                || attacking_player.character.name == Name::Muflus)
        {
            return Ok(Vec::new());
        }

        let now = time_now();
        attacking_player.action = PlayerAction::EXECUTINGSKILL3;
        attacking_player.skill_3_started_at = now;
        attacking_player.skill_3_cooldown_left = attacking_player.skill_3_cooldown();
        attacking_player.skill_3_ends_at = add_millis(now, attacking_player.skill_3_cooldown_left);
        attacking_player.direction = *direction;

        attacking_player.add_effect(
            Effect::NeonCrashing,
            false,
            EffectData {
                time_left: attacking_player.character.duration_skill_3(),
                ends_at: add_millis(now, attacking_player.character.duration_skill_3()),
                duration: attacking_player.character.duration_skill_3(),
                direction: Some(*direction),
                position: None,
                triggered_at: u128_to_millis(0),
                caused_by: attacking_player.id,
                caused_to: attacking_player.id,
                damage: 0,
            },
        );

        Ok(Vec::new())
    }

    //     if direction.x != 0f32 || direction.y != 0f32 {
    //         let piercing = attacking_player.has_active_effect(&Effect::DenialOfService);

    //         let angle = (direction.y as f32).atan2(direction.x as f32); // Calculates the angle in radians.
    //         let angle_positive = if angle < 0.0 {
    //             (angle + 2.0 * PI).to_degrees() // Adjusts the angle if negative.
    //         } else {
    //             angle.to_degrees()
    //         };

    //         let angle_modifiers = [-20f32, -10f32, 0f32, 10f32, 20f32];

    //         let mut speed = attacking_player.character.par_1_skill_1() as f32;
    //         if piercing {
    //             speed *= 1.25;
    //         }

    //         for modifier in angle_modifiers {
    //             let projectile = Projectile::new(
    //                 *next_projectile_id,
    //                 attacking_player.position,
    //                 RelativePosition::new(
    //                     (angle_positive + modifier).to_radians().cos(),
    //                     (angle_positive + modifier).to_radians().sin(),
    //                 ),
    //                 speed as u32,
    //                 1,
    //                 attacking_player.id,
    //                 attacking_player.skill_1_damage(),
    //                 30,
    //                 ProjectileType::BULLET,
    //                 ProjectileStatus::ACTIVE,
    //                 attacking_player.id,
    //                 piercing,
    //                 "MULTISHOT".to_string(),
    //             );
    //             projectiles.push(projectile);
    //             (*next_projectile_id) += 1;
    //         }
    //     }
    //     Ok(Vec::new())
    // }

    pub fn muflus_skill_1(
        players: &mut Vec<Player>,
        attacking_player_id: u64,
        now: MillisTime,
    ) -> Result<Vec<u64>, String> {
        let pys = players.clone();
        let attacking_player = GameState::get_player_mut(players, attacking_player_id)?;
        let attack_dmg = attacking_player.skill_1_damage() as i64;

        let extra_effect = GameState::get_extra_effect(attacking_player, now);

        // TODO: This should be a config of the attack
        let attack_range: f64 = attacking_player.skill_1_range();

        let mut affected_players: Vec<u64> =
            GameState::players_in_range(&pys, &attacking_player.position, attack_range)
                .into_iter()
                .filter(|&(id, _distance)| id != attacking_player_id)
                .map(|(id, _distance)| id)
                .collect();

        for target_player_id in affected_players.iter_mut() {
            // FIXME: This is not ok, we should save referencies to the Game Players this is redundant
            let attacked_player = players
                .iter_mut()
                .find(|player| player.id == *target_player_id && player.id != attacking_player_id);

            match attacked_player {
                Some(ap) => {
                    ap.modify_health(-attack_dmg);

                    match extra_effect {
                        Some((effect, effect_data)) => {
                            let mut effect_data = effect_data.clone();
                            effect_data.caused_to = ap.id;
                            ap.add_effect(effect, false, effect_data);
                        }
                        None => (),
                    }
                }
                _ => continue,
            }
        }
        Ok(affected_players)
    }

    pub fn _dagna_skill_1(
        players: &mut Vec<Player>,
        attacking_player_id: u64,
    ) -> Result<Vec<u64>, String> {
        let pys = players.clone();
        let attacking_player = GameState::get_player_mut(players, attacking_player_id)?;
        let duration = attacking_player.character.duration_skill_1();
        let damage = attacking_player.skill_1_damage();

        let now = time_now();

        // TODO: This should be a config of the attack
        let attack_range = 1000.;

        let mut affected_players: Vec<u64> =
            GameState::players_in_range(&pys, &attacking_player.position, attack_range)
                .into_iter()
                .filter(|&(id, _distance)| id != attacking_player_id)
                .map(|(id, _distance)| id)
                .collect();

        for target_player_id in affected_players.iter_mut() {
            // FIXME: This is not ok, we should save referencies to the Game Players this is redundant
            let attacked_player = GameState::get_player_mut(players, *target_player_id)?;

            attacked_player.add_effect(
                Effect::DanseMacabre.clone(),
                false,
                EffectData {
                    time_left: duration,
                    ends_at: add_millis(now, duration),
                    duration: duration,
                    direction: None,
                    position: None,
                    triggered_at: now,
                    caused_by: attacking_player_id,
                    caused_to: attacked_player.id,
                    damage: damage,
                },
            )
        }
        Ok(affected_players)
    }

    pub fn skill_2(
        self: &mut Self,
        attacking_player_id: u64,
        direction: &RelativePosition,
    ) -> Result<(), String> {
        let pys = self.players.clone();
        let attacking_player = GameState::get_player_mut(&mut self.players, attacking_player_id)?;

        if !attacking_player.can_attack(attacking_player.skill_2_cooldown_left, false) {
            return Ok(());
        }

        let now = time_now();
        attacking_player.action = PlayerAction::EXECUTINGSKILL2;
        attacking_player.skill_2_started_at = now;
        attacking_player.skill_2_cooldown_left = attacking_player.skill_2_cooldown();
        attacking_player.skill_2_ends_at = add_millis(now, attacking_player.skill_2_cooldown_left);
        attacking_player.direction = *direction;
        let attack_angle = attacking_player.skill_2_angle();

        let attacked_player_ids = match attacking_player.character.name {
            Name::H4ck => Self::h4ck_skill_2(
                &attacking_player,
                direction,
                &mut self.projectiles,
                &mut self.next_projectile_id,
            ),
            Name::Muflus => Self::muflus_skill_2(attacking_player),
            Name::Uma => {
                let attacking_player =
                    GameState::get_player_mut(&mut self.players, attacking_player_id)?;
                let attacking_player_id = attacking_player.id;
                let duration = attacking_player.character.duration_skill_2();

                match Self::nearest_player(
                    &pys,
                    &attacking_player.position,
                    &attacking_player.direction,
                    attacking_player.id,
                    1000.,
                    attack_angle,
                ) {
                    Some((player_id, _position)) => {
                        attacking_player.add_effect(
                            Effect::XandaMarkOwner,
                            true,
                            EffectData {
                                time_left: duration,
                                ends_at: add_millis(now, duration),
                                duration: duration,
                                direction: None,
                                position: None,
                                triggered_at: u128_to_millis(0),
                                caused_by: attacking_player.id,
                                caused_to: player_id,
                                damage: 0,
                            },
                        );

                        let attacked_player =
                            GameState::get_player_mut(&mut self.players, player_id)?;
                        attacked_player.add_effect(
                            Effect::XandaMark,
                            true,
                            EffectData {
                                time_left: duration,
                                ends_at: add_millis(now, duration),
                                duration: duration,
                                direction: None,
                                position: None,
                                triggered_at: now,
                                caused_by: attacking_player_id,
                                caused_to: attacked_player.id,
                                damage: 0,
                            },
                        );
                    }
                    None => (),
                };
                Ok(Vec::new())
            }
            _ => Ok(Vec::new()),
        };

        self.update_killfeed(attacking_player_id, attacked_player_ids?);
        Ok(())
    }

    pub fn h4ck_skill_2(
        attacking_player: &Player,
        direction: &RelativePosition,
        projectiles: &mut Vec<Projectile>,
        next_projectile_id: &mut u64,
    ) -> Result<Vec<u64>, String> {
        if direction.x != 0f32 || direction.y != 0f32 {
            let projectile = Projectile::new(
                *next_projectile_id,
                attacking_player.position,
                RelativePosition::new(direction.x as f32, direction.y as f32),
                140,
                10,
                attacking_player.id,
                attacking_player.skill_2_damage(),
                100,
                ProjectileType::DISARMINGBULLET,
                ProjectileStatus::ACTIVE,
                attacking_player.id,
                false,
                "DISARM".to_string(),
            );
            projectiles.push(projectile);
            (*next_projectile_id) += 1;
        }
        Ok(Vec::new())
    }

    pub fn skill_3(
        self: &mut Self,
        attacking_player_id: u64,
        direction: &RelativePosition,
    ) -> Result<(), String> {
        let attacking_player = GameState::get_player_mut(&mut self.players, attacking_player_id)?;

        if !attacking_player.can_attack(attacking_player.skill_3_cooldown_left, false) {
            return Ok(());
        }

        if attacking_player.has_active_effect(&Effect::Paralyzed)
            && (attacking_player.character.name == Name::H4ck
                || attacking_player.character.name == Name::Muflus)
        {
            return Ok(());
        }

        let now = time_now();
        attacking_player.action = PlayerAction::EXECUTINGSKILL3;
        attacking_player.skill_3_started_at = now;
        attacking_player.skill_3_cooldown_left = attacking_player.skill_3_cooldown();
        attacking_player.skill_3_ends_at = add_millis(now, attacking_player.skill_3_cooldown_left);
        attacking_player.direction = *direction;

        let attacked_player_ids: Result<Vec<u64>, String> = match attacking_player.character.name {
            Name::H4ck => {
                // attacking_player.add_effect(
                //     Effect::NeonCrashing,
                //     false,
                //     EffectData {
                //         time_left: attacking_player.character.duration_skill_3(),
                //         ends_at: add_millis(now, attacking_player.character.duration_skill_3()),
                //         duration: attacking_player.character.duration_skill_3(),
                //         direction: Some(*direction),
                //         position: None,
                //         triggered_at: u128_to_millis(0),
                //         caused_by: attacking_player.id,
                //         caused_to: attacking_player.id,
                //         damage: 0,
                //     },
                // );
                attacking_player.add_effect(
                    Effect::DenialOfService,
                    false,
                    EffectData {
                        time_left: attacking_player.character.duration_skill_4(),
                        ends_at: add_millis(now, attacking_player.character.duration_skill_4()),
                        duration: attacking_player.character.duration_skill_4(),
                        direction: None,
                        position: None,
                        triggered_at: u128_to_millis(0),
                        caused_by: attacking_player.id,
                        caused_to: attacking_player.id,
                        damage: 0,
                    },
                );

                Ok(Vec::new())
            }
            Name::Muflus => {
                let position = GameState::new_position(
                    attacking_player.position,
                    direction,
                    self.board.height,
                    self.board.width,
                );
                let distance = distance_between_positions(&attacking_player.position, &position);
                let time = distance * attacking_player.character.base_speed as f64 / 48.;

                attacking_player.action = PlayerAction::STARTINGSKILL3;
                attacking_player.add_effect(
                    Effect::Leaping,
                    false,
                    EffectData {
                        time_left: MillisTime {
                            high: 0,
                            low: time as u64,
                        },
                        ends_at: add_millis(
                            now,
                            MillisTime {
                                high: 0,
                                low: time as u64,
                            },
                        ),
                        duration: MillisTime {
                            high: 0,
                            low: time as u64,
                        },
                        direction: Some(*direction),
                        position: Some(position),
                        triggered_at: u128_to_millis(0),
                        caused_by: attacking_player.id,
                        caused_to: attacking_player.id,
                        damage: 0,
                    },
                );

                Ok(Vec::new())
            }
            Name::Uma => GameState::uma_skill_3(&mut self.players, attacking_player_id),

            _ => Ok(Vec::new()),
        };

        self.update_killfeed(attacking_player_id, attacked_player_ids?);
        Ok(())
    }

    pub fn muflus_skill_2(attacking_player: &mut Player) -> Result<Vec<u64>, String> {
        let now = time_now();
        attacking_player.add_effect(
            Effect::Raged,
            false,
            EffectData {
                time_left: attacking_player.character.duration_skill_2(),
                ends_at: add_millis(now, attacking_player.character.duration_skill_2()),
                duration: attacking_player.character.duration_skill_2(),
                direction: None,
                position: None,
                triggered_at: u128_to_millis(0),
                caused_by: attacking_player.id,
                caused_to: attacking_player.id,
                damage: 0,
            },
        );
        Ok(Vec::new())
    }

    pub fn skill_4(
        self: &mut Self,
        attacking_player_id: u64,
        direction: &RelativePosition,
    ) -> Result<(), String> {
        let attacking_player = GameState::get_player_mut(&mut self.players, attacking_player_id)?;

        if !attacking_player.can_attack(attacking_player.skill_4_cooldown_left, false) {
            return Ok(());
        }

        let now = time_now();
        attacking_player.action = PlayerAction::EXECUTINGSKILL4;
        attacking_player.skill_4_started_at = now;
        attacking_player.skill_4_cooldown_left = attacking_player.skill_4_cooldown();
        attacking_player.skill_4_ends_at = add_millis(now, attacking_player.skill_4_cooldown_left);
        attacking_player.direction = *direction;

        let attacked_player_ids: Result<Vec<u64>, String> = match attacking_player.character.name {
            Name::H4ck => {
                attacking_player.add_effect(
                    Effect::DenialOfService,
                    false,
                    EffectData {
                        time_left: attacking_player.character.duration_skill_4(),
                        ends_at: add_millis(now, attacking_player.character.duration_skill_4()),
                        duration: attacking_player.character.duration_skill_4(),
                        direction: None,
                        position: None,
                        triggered_at: u128_to_millis(0),
                        caused_by: attacking_player.id,
                        caused_to: attacking_player.id,
                        damage: 0,
                    },
                );
                attacking_player.basic_skill_ends_at = add_millis(
                    attacking_player.basic_skill_started_at,
                    attacking_player.basic_skill_cooldown(),
                );
                attacking_player.skill_1_ends_at = add_millis(
                    attacking_player.skill_1_started_at,
                    attacking_player.skill_1_cooldown(),
                );
                attacking_player.skill_2_ends_at = add_millis(
                    attacking_player.skill_2_started_at,
                    attacking_player.skill_2_cooldown(),
                );
                attacking_player.skill_3_ends_at = add_millis(
                    attacking_player.skill_3_started_at,
                    attacking_player.skill_3_cooldown(),
                );
                Ok(Vec::new())
            }
            Name::Muflus => {
                attacking_player.add_effect(
                    Effect::FieryRampage,
                    false,
                    EffectData {
                        time_left: attacking_player.character.duration_skill_4(),
                        ends_at: add_millis(now, attacking_player.character.duration_skill_4()),
                        duration: attacking_player.character.duration_skill_4(),
                        direction: None,
                        position: None,
                        triggered_at: u128_to_millis(0),
                        caused_by: attacking_player.id,
                        caused_to: attacking_player.id,
                        damage: 0,
                    },
                );
                Ok(Vec::new())
            }
            _ => Ok(Vec::new()),
        };

        self.update_killfeed(attacking_player_id, attacked_player_ids?);
        Ok(())
    }

    pub fn uma_skill_3(
        players: &mut Vec<Player>,
        attacking_player_id: u64,
    ) -> Result<Vec<u64>, String> {
        let mut affected_players: Vec<u64> = vec![];

        for target_player in players.iter_mut() {
            let marks_count = target_player.marks_per_player(attacking_player_id);

            if target_player.id == attacking_player_id
                || matches!(target_player.status, Status::DEAD)
                || marks_count == 0
            {
                continue;
            }
            let damage = min(45, 15 * marks_count);
            target_player.modify_health(-(damage as f64) as i64);

            target_player.remove_uma_marks();
            affected_players.push(target_player.id);
        }
        Ok(affected_players)
    }

    pub fn disconnect(self: &mut Self, player_id: u64) -> Result<(), String> {
        if let Some(player) = self.players.get_mut((player_id - 1) as usize) {
            player.status = Status::DISCONNECTED;
            Ok(())
        } else {
            Err(format!("Player not found with id: {}", player_id))
        }
    }

    pub fn world_tick(self: &mut Self, out_of_area_damage: i64) -> Result<(), String> {
        let now = time_now();
        let pys = self.players.clone();

        // Status effects
        let mut neon_crash_affected_players: HashMap<
            u64,
            (Vec<(u64, i64)>, Option<(Effect, MillisTime)>),
        > = HashMap::new();
        let mut leap_affected_players: HashMap<
            u64,
            (Vec<(u64, i64)>, Option<(Effect, MillisTime)>),
        > = HashMap::new();
        let mut uma_mirroring_affected_players: HashMap<u64, (i64, u64)> = HashMap::new();
        let mut scherzo_affected_players: HashMap<
            u64,
            (Vec<(u64, i64)>, Option<(Effect, MillisTime)>),
        > = HashMap::new();
        let mut projectile_affected_players: HashMap<u64, (i64, Vec<u64>)> = HashMap::new();

        self.players.iter_mut().for_each(|player| {
            // Clean each player actions
            player.action = PlayerAction::NOTHING;
            player.update_cooldowns(now);
            let damage = player.skill_1_damage() as i64;
            let attack_range = player.skill_1_range();
            // Keep only (de)buffs that have
            // a non-zero amount of ticks left.
            player.effects.retain(
                |effect,
                 EffectData {
                     time_left, ends_at, ..
                 }| {
                    *time_left = sub_millis(*ends_at, now);

                    if player.character.name == Name::Muflus
                        && millis_to_u128(*time_left) == 0
                        && effect == &Effect::Leaping
                    {
                        player.action = PlayerAction::EXECUTINGSKILL3;
                        let af_pl = GameState::affected_players(
                            damage,
                            attack_range,
                            &pys,
                            &player.position,
                            player.id,
                        );
                        let effect = Effect::Slowed;
                        let duration = player.character.duration_skill_3();
                        leap_affected_players.insert(player.id, (af_pl, Some((effect, duration))));
                    }
                    millis_to_u128(*time_left) > 0
                },
            );

            if player.character.name == Name::H4ck {
                match player.effects.get(&Effect::NeonCrashing) {
                    Some(EffectData {
                        direction: Some(direction),
                        ..
                    }) => {
                        let speed = player.speed() as i64;
                        GameState::move_player_to_direction(
                            &mut self.board,
                            &mut player.position,
                            direction,
                            speed,
                        )
                        .unwrap();

                        let damage_neon_crash = player.skill_3_damage() as i64;
                        let range_neon_crash = player.skill_3_range() as f64;

                        let af_pl = GameState::affected_players(
                            damage_neon_crash,
                            range_neon_crash,
                            &pys,
                            &player.position,
                            player.id,
                        );
                        neon_crash_affected_players.insert(player.id, (af_pl, None));
                    }
                    _ => {}
                }
            }

            if player.character.name == Name::Muflus {
                match player.effects.get(&Effect::Leaping) {
                    Some(EffectData {
                        direction: Some(direction),
                        ..
                    }) => {
                        let speed = player.speed() as i64;
                        GameState::move_player_to_direction(
                            &mut self.board,
                            &mut player.position,
                            direction,
                            speed,
                        )
                        .unwrap();
                    }
                    _ => {}
                }
            }

            if player.character.name == Name::DAgna {
                match player.effects.get(&Effect::Scherzo) {
                    Some(data) => {
                        let mut effect_data = data.clone();
                        if millis_to_u128(sub_millis(now, effect_data.triggered_at)) > 1000 as u128
                        {
                            let af_pl = GameState::affected_players_gradient(
                                effect_data.damage as i64,
                                1000.,
                                &pys,
                                &player.position,
                                player.id,
                            );
                            scherzo_affected_players.insert(player.id, (af_pl, None));
                            effect_data.triggered_at = now;
                        }

                        player.effects.insert(Effect::Scherzo, effect_data);
                    }
                    None => {}
                };
            }
        });

        // Neon Crash Attack
        // We can have more than one h4ck attacking
        self.attack_players_with_effect(neon_crash_affected_players, now)?;

        // Leap Attack
        // We can have more than one muflus attacking
        self.attack_players_with_effect(leap_affected_players, now)?;

        // Scherzo Attack
        // We can have more than one D'Agna attacking
        self.attack_players_with_effect(scherzo_affected_players, now)?;

        // Update projectiles
        // - Retain active projectiles
        // - Update positions
        GameState::update_projectiles(&mut self.projectiles, self.board.height, self.board.width);

        for projectile in self.projectiles.iter_mut() {
            if projectile.status == ProjectileStatus::ACTIVE {
                let affected_players: HashMap<u64, f64> =
                    GameState::players_in_projectile_movement(
                        projectile.player_id,
                        &self.players,
                        projectile.position,
                    )
                    .into_iter()
                    .filter(|&(id, _distance)| {
                        id != projectile.player_id && id != projectile.last_attacked_player_id
                    })
                    .collect();

                // A projectile should attack only one player per tick
                if affected_players.len() > 0 {
                    // if there are more than one player affected by the projectile
                    // finde the nearest one
                    let (attacked_player_id, _) = affected_players
                        .iter()
                        .min_by(|a, b| cmp_float(*a.1, *b.1))
                        .unwrap();
                    let attacked_player =
                        GameState::get_player_mut(&mut self.players, *attacked_player_id)?;
                    if !projectile.pierce {
                        projectile.status = ProjectileStatus::EXPLODED;
                        projectile.position = attacked_player.position;
                    }
                    match projectile.projectile_type {
                        ProjectileType::DISARMINGBULLET => {
                            attacked_player.add_effect(
                                Effect::Paralyzed,
                                false,
                                EffectData {
                                    time_left: MillisTime { high: 0, low: 5000 },
                                    ends_at: add_millis(now, MillisTime { high: 0, low: 5000 }),
                                    duration: MillisTime { high: 0, low: 5000 },
                                    direction: None,
                                    position: None,
                                    triggered_at: u128_to_millis(0),
                                    caused_by: projectile.player_id,
                                    caused_to: attacked_player.id,
                                    damage: 0,
                                },
                            );
                        }
                        _ => {
                            attacked_player.modify_health(-(projectile.damage as i64));
                            projectile_affected_players
                                .entry(projectile.player_id)
                                .and_modify(|at| at.1.push(attacked_player.id))
                                .or_insert((0, vec![attacked_player.id]));

                            match attacked_player.get_mirrored_player_id() {
                                Some(mirrored_id) => uma_mirroring_affected_players.insert(
                                    attacked_player.id,
                                    ((projectile.damage as i64) / 2, mirrored_id),
                                ),
                                None => None,
                            };
                            projectile.last_attacked_player_id = attacked_player.id;
                        }
                    }
                }
            }
        }

        for (player_id, (_, attacked_players)) in projectile_affected_players.iter() {
            let attacked = attacked_players.clone();
            self.update_killfeed(*player_id, attacked);
        }

        self.attack_mirrored_player(uma_mirroring_affected_players)?;

        self.check_and_damage_outside_playable(out_of_area_damage);

        self.check_and_damage_players(Effect::Poisoned);

        self.check_and_damage_players(Effect::Burned);

        self.killfeed = self.next_killfeed.clone();
        self.next_killfeed.clear();

        Ok(())
    }

    fn check_and_damage_players(self: &mut Self, effect: Effect) {
        let now = time_now();
        let mut poisoned_affected_players: HashMap<u64, (i64, Vec<u64>)> = HashMap::new();
        self.players.iter_mut().for_each(|player| {
            if matches!(player.status, Status::DEAD) {
                return;
            }
            let mut effect_data = match player.effects.get(&effect) {
                Some(data) => data.clone(),
                None => return,
            };

            let time_between_hits = (1000 / 2) as u32;

            // Damage is evenly distributed between the duration of the effect
            let damage = effect_data.damage / (effect_data.duration.low as u32 / time_between_hits);

            if millis_to_u128(sub_millis(now, effect_data.triggered_at)) > time_between_hits as u128
            {
                if effect == Effect::Poisoned && player.has_active_effect(&Effect::YugenMark) {
                    player.modify_health_without_killing(-(damage as i64));
                } else {
                    player.modify_health(-(damage as i64));
                }
                effect_data.triggered_at = now;
            }
            poisoned_affected_players
                .entry(effect_data.caused_by)
                .and_modify(|at| at.1.push(player.id))
                .or_insert((0, vec![player.id]));

            player.effects.insert(effect, effect_data);
        });

        for (player_id, (_, attacked_players)) in poisoned_affected_players.iter() {
            let attacked = attacked_players.clone();
            self.update_killfeed(*player_id, attacked);
        }
    }

    fn update_projectiles(
        projectiles: &mut Vec<Projectile>,
        board_height: usize,
        board_width: usize,
    ) {
        projectiles.retain(|projectile| {
            projectile.remaining_ticks > 0 && projectile.status == ProjectileStatus::ACTIVE
        });

        projectiles.iter_mut().for_each(|projectile| {
            projectile.move_or_explode_if_out_of_board(board_height, board_width);
            projectile.remaining_ticks = projectile.remaining_ticks.saturating_sub(1);
        });
    }

    fn attack_players_with_effect(
        self: &mut Self,
        affected_players: HashMap<u64, (Vec<(u64, i64)>, Option<(Effect, MillisTime)>)>,
        now: MillisTime,
    ) -> Result<(), String> {
        let mut uma_mirroring_affected_players: HashMap<u64, (i64, u64)> = HashMap::new();
        for (player_id, (attacked_players, effect)) in affected_players.iter() {
            for (target_player_id, damage) in attacked_players.iter() {
                let attacked_player = self
                    .players
                    .iter_mut()
                    .find(|player| player.id == *target_player_id && player.id != *player_id);
                match attacked_player {
                    Some(ap) => {
                        ap.modify_health(-damage);
                        match effect {
                            Some((effect, duration)) => {
                                let effect_data = EffectData {
                                    time_left: *duration,
                                    ends_at: add_millis(now, *duration),
                                    duration: *duration,
                                    direction: None,
                                    position: None,
                                    triggered_at: now,
                                    caused_by: *player_id,
                                    caused_to: ap.id,
                                    damage: 0,
                                };
                                ap.add_effect(effect.clone(), false, effect_data.clone());
                            }
                            None => {}
                        }
                        match ap.get_mirrored_player_id() {
                            Some(mirrored_id) => uma_mirroring_affected_players
                                .insert(ap.id, (damage / 2, mirrored_id)),
                            None => None,
                        };
                    }
                    _ => continue,
                }
            }
            let attacked = attacked_players.iter().map(|&(id, _damage)| id).collect();
            self.update_killfeed(*player_id, attacked);
        }
        self.attack_mirrored_player(uma_mirroring_affected_players)?;
        Ok(())
    }

    fn attack_mirrored_player(
        self: &mut Self,
        affected_players: HashMap<u64, (i64, u64)>,
    ) -> Result<(), String> {
        for (_player_id, (damage, attacked_player_id)) in affected_players.iter() {
            let attacked_player =
                GameState::get_player_mut(&mut self.players, *attacked_player_id)?;
            if !matches!(attacked_player.status, Status::DEAD) {
                attacked_player.modify_health_without_killing(-damage);
            }
        }

        Ok(())
    }

    fn affected_players(
        attack_damage: i64,
        attack_range: f64,
        players: &Vec<Player>,
        attacking_player_position: &Position,
        attacking_player_id: u64,
    ) -> Vec<(u64, i64)> {
        GameState::players_in_range(players, attacking_player_position, attack_range)
            .into_iter()
            .filter(|&(id, _distance)| id != attacking_player_id)
            .map(|(id, _distance)| (id, attack_damage))
            .collect()
    }

    fn affected_players_gradient(
        max_attack_damage: i64,
        attack_range: f64,
        players: &Vec<Player>,
        attacking_player_position: &Position,
        attacking_player_id: u64,
    ) -> Vec<(u64, i64)> {
        GameState::players_in_range(players, attacking_player_position, attack_range)
            .into_iter()
            .filter(|&(id, _distance)| id != attacking_player_id)
            .map(|(id, distance)| {
                (
                    id,
                    (max_attack_damage as f64 - max_attack_damage as f64 * distance / attack_range)
                        as i64,
                )
            })
            .collect()
    }

    pub fn spawn_player(self: &mut Self, player_id: u64) {
        let mut tried_positions = HashSet::new();
        let position: Position;

        position = generate_new_position(&mut tried_positions, self.board.width, self.board.height);

        self.players
            .push(Player::new(player_id, 100, position, Default::default()));
    }

    pub fn shrink_map(self: &mut Self, map_shrink_minimum_radius: u64) {
        let new_radius = self.playable_radius - 10; // self.playable_radius.mul(1).div(100).div(5);
        self.playable_radius = new_radius.max(map_shrink_minimum_radius);
    }

    pub fn spawn_loot(self: &mut Self) {
        let id = self.next_loot_id;
        self.next_loot_id += 1;

        let loot = loot::spawn_random_loot(id, self.board.height, self.board.width);
        self.loots.push(loot);
    }

    fn update_killfeed(self: &mut Self, attacking_player_id: u64, attacked_player_ids: Vec<u64>) {
        let mut kill_events: Vec<KillEvent> = attacked_player_ids
            .into_iter()
            .unique()
            .filter(|player_id| {
                self.players
                    .iter()
                    .find(|player| player.id == *player_id && matches!(player.status, Status::DEAD))
                    .is_some()
            })
            .map(|killed_player| KillEvent {
                kill_by: attacking_player_id,
                killed: killed_player,
            })
            .collect();

        add_kills(
            &mut self.players,
            attacking_player_id,
            kill_events.len() as u64,
        )
        .unwrap();

        self.next_killfeed.append(&mut kill_events);
    }

    fn check_and_damage_outside_playable(self: &mut Self, out_of_area_damage: i64) {
        let now = time_now();
        let time_left = u128_to_millis(3_600_000); // 1 hour
        let duration = u128_to_millis(3_600_000); // 1 hour
        let ends_at = add_millis(now, time_left);
        let player_ids_in_playable: Vec<u64> = GameState::players_in_range(
            &self.players,
            &self.shrinking_center,
            self.playable_radius as f64,
        )
        .into_iter()
        .map(|(id, _distance)| id)
        .collect();

        self.players.iter_mut().for_each(|player| {
            if player_ids_in_playable.contains(&player.id) {
                player.effects.remove(&Effect::OutOfArea);
            } else {
                let mut effect_data = match player.effects.get(&Effect::OutOfArea) {
                    None => EffectData {
                        time_left,
                        ends_at,
                        duration,
                        direction: None,
                        position: None,
                        triggered_at: now,
                        caused_by: player.id,
                        caused_to: player.id,
                        damage: 0,
                    },
                    Some(data) => data.clone(),
                };

                if millis_to_u128(sub_millis(now, effect_data.triggered_at)) > 1000 {
                    player.modify_health(-out_of_area_damage);
                    effect_data.triggered_at = now;
                }

                player.effects.insert(Effect::OutOfArea, effect_data);
            }
        });
    }
}
/// Given a position and a direction, returns the position adjacent to it `n` tiles
/// in that direction
/// Example: If the arguments are Direction::RIGHT, (0, 0) and 2, returns (0, 2).
fn compute_adjacent_position_n_tiles(
    direction: &Direction,
    position: &Position,
    n: usize,
) -> Position {
    let x = position.x;
    let y = position.y;

    // Avoid overflow with saturated ops.
    match direction {
        Direction::UP => Position::new(x.saturating_sub(n), y),
        Direction::DOWN => Position::new(x + n, y),
        Direction::LEFT => Position::new(x, y.saturating_sub(n)),
        Direction::RIGHT => Position::new(x, y + n),
    }
}

/// TODO: update documentation
/// Checks if the given movement from `old_position` to `new_position` is valid.
/// The way we do it is separated into cases but the idea is always the same:
/// First of all check that we are not trying to move away from the board.
/// Then go through the tiles that are between the new_position and the old_position
/// and ensure that each one of them is empty. If that's not the case, the movement is
/// invalid; otherwise it's valid.
/// The cases that we separate the check into are the following:
/// - Movement is in the Y direction. This is divided into two other cases:
///     - Movement increases the Y coordinate (new_position.y > old_position.y).
///     - Movement decreases the Y coordinate (new_position.y < old_position.y).
/// - Movement is in the X direction. This is also divided into two cases:
///     - Movement increases the X coordinate (new_position.x > old_position.x).
///     - Movement decreases the X coordinate (new_position.x < old_position.x).
// fn tile_to_move_to(board: &Board, old_position: &Position, new_position: &Position) -> Position {
//     let mut number_of_cells_to_move = 0;

//     if new_position.x == old_position.x {
//         if new_position.y > old_position.y {
//             for i in 1..(new_position.y - old_position.y) + 1 {
//                 let cell = board.get_cell(old_position.x, old_position.y + i);

//                 match cell {
//                     Some(Tile::Empty) => {
//                         number_of_cells_to_move += 1;
//                         continue;
//                     }
//                     None => continue,
//                     Some(_) => {
//                         return Position {
//                             x: old_position.x,
//                             y: old_position.y + number_of_cells_to_move,
//                         };
//                     }
//                 }
//             }
//             return Position {
//                 x: old_position.x,
//                 y: old_position.y + number_of_cells_to_move,
//             };
//         } else {
//             for i in 1..(old_position.y - new_position.y) + 1 {
//                 let cell = board.get_cell(old_position.x, old_position.y - i);

//                 match cell {
//                     Some(Tile::Empty) => {
//                         number_of_cells_to_move += 1;
//                         continue;
//                     }
//                     None => continue,
//                     Some(_) => {
//                         return Position {
//                             x: old_position.x,
//                             y: old_position.y - number_of_cells_to_move,
//                         };
//                     }
//                 }
//             }
//             return Position {
//                 x: old_position.x,
//                 y: old_position.y - number_of_cells_to_move,
//             };
//         }
//     } else {
//         if new_position.x > old_position.x {
//             for i in 1..(new_position.x - old_position.x) + 1 {
//                 let cell = board.get_cell(old_position.x + i, old_position.y);

//                 match cell {
//                     Some(Tile::Empty) => {
//                         number_of_cells_to_move += 1;
//                         continue;
//                     }
//                     None => continue,
//                     Some(_) => {
//                         return Position {
//                             x: old_position.x + number_of_cells_to_move,
//                             y: old_position.y,
//                         }
//                     }
//                 }
//             }
//             return Position {
//                 x: old_position.x + number_of_cells_to_move,
//                 y: old_position.y,
//             };
//         } else {
//             for i in 1..(old_position.x - new_position.x) + 1 {
//                 let cell = board.get_cell(old_position.x - i, old_position.y);

//                 match cell {
//                     Some(Tile::Empty) => {
//                         number_of_cells_to_move += 1;
//                         continue;
//                     }
//                     None => continue,
//                     Some(_) => {
//                         return Position {
//                             x: old_position.x - number_of_cells_to_move,
//                             y: old_position.y,
//                         }
//                     }
//                 }
//             }
//             return Position {
//                 x: old_position.x - number_of_cells_to_move,
//                 y: old_position.y,
//             };
//         }
//     }
// }

#[allow(dead_code)]
fn distance_to_center(player: &Player, center: &Position) -> f64 {
    let distance_squared =
        (player.position.x - center.x).pow(2) + (player.position.y - center.y).pow(2);
    (distance_squared as f64).sqrt()
}

#[allow(dead_code)]
fn distance_between_positions(position_1: &Position, position_2: &Position) -> f64 {
    let distance_squared =
        (position_1.x - position_2.x).pow(2) + (position_1.y - position_2.y).pow(2);
    (distance_squared as f64).sqrt()
}

fn calculate_hypotenuse(base: u64, altitude: u64) -> u64 {
    let squared_hypotenuse = base.pow(2) + altitude.pow(2);
    (squared_hypotenuse as f64).sqrt() as u64
}

// We might want to abstract this into a Vector2 type or something, whatever.
fn normalize_vector(x: f32, y: f32) -> (f32, f32) {
    let norm = f32::sqrt(x.powf(2.) + y.powf(2.));
    (x / norm, y / norm)
}

fn generate_new_position(
    positions: &mut HashSet<(usize, usize)>,
    board_width: usize,
    board_height: usize,
) -> Position {
    let rng = &mut thread_rng();
    let mut x_coordinate: usize = rng.gen_range(0..board_width);
    let mut y_coordinate: usize = rng.gen_range(0..board_height);

    while positions.contains(&(x_coordinate, y_coordinate)) {
        x_coordinate = rng.gen_range(0..board_width);
        y_coordinate = rng.gen_range(0..board_height);
    }

    positions.insert((x_coordinate, y_coordinate));
    Position::new(x_coordinate, y_coordinate)
}

pub fn new_entity_position(
    height: usize,
    width: usize,
    direction_x: f32,
    direction_y: f32,
    entity_position: Position,
    entity_speed: i64,
) -> Position {
    let Position { x: old_x, y: old_y } = entity_position;
    let speed = entity_speed as i64;

    /*
        We take the joystick coordinates, normalize the vector, then multiply by speed,
        then round the values.
    */
    let (movement_direction_x, movement_direction_y) = normalize_vector(-direction_y, direction_x);
    let movement_vector_x = movement_direction_x * (speed as f32);
    let movement_vector_y = movement_direction_y * (speed as f32);

    let mut new_position_x = old_x as i64 + (movement_vector_x.round() as i64);
    let mut new_position_y = old_y as i64 + (movement_vector_y.round() as i64);

    new_position_x = min(new_position_x, (height - 1) as i64);
    new_position_x = max(new_position_x, 0);
    new_position_y = min(new_position_y, (width - 1) as i64);
    new_position_y = max(new_position_y, 0);

    let new_position = Position {
        x: new_position_x as usize,
        y: new_position_y as usize,
    };
    new_position
}

fn add_kills(
    players: &mut Vec<Player>,
    attacking_player_id: u64,
    kills: u64,
) -> Result<(), String> {
    let attacking_player = GameState::get_player_mut(players, attacking_player_id)?;
    attacking_player.add_kills(kills);
    Ok(())
}
