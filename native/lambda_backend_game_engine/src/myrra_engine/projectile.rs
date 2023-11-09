use super::game;
use super::player::Position;
use super::utils::RelativePosition;
use rustler::NifStruct;
use rustler::NifUnitEnum;

pub type TicksLeft = u64;

#[derive(Debug, Clone, NifStruct)]
#[module = "LambdaGameEngine.MyrraEngine.Projectile"]
pub struct Projectile {
    pub id: u64,
    pub position: Position,
    pub prev_position: Position,
    pub direction: RelativePosition,
    pub speed: u32,
    pub range: u32,
    pub player_id: u64,
    pub damage: u32,
    pub remaining_ticks: TicksLeft,
    pub projectile_type: ProjectileType,
    pub status: ProjectileStatus,
    pub last_attacked_player_id: u64,
    pub pierce: bool,
    pub skill_name: String,
}

#[derive(Debug, Clone, NifUnitEnum)]
pub enum ProjectileType {
    BULLET,
    DISARMINGBULLET,
}

#[derive(Debug, Clone, NifUnitEnum, PartialEq)]
pub enum ProjectileStatus {
    ACTIVE,
    EXPLODED,
}

impl Projectile {
    pub fn new(
        id: u64,
        position: Position,
        direction: RelativePosition,
        speed: u32,
        range: u32,
        player_id: u64,
        damage: u32,
        remaining_ticks: TicksLeft,
        projectile_type: ProjectileType,
        status: ProjectileStatus,
        last_attacked_player_id: u64,
        pierce: bool,
        skill_name: String,
    ) -> Self {
        Self {
            id,
            position,
            prev_position: position.clone(),
            direction,
            speed,
            range,
            player_id,
            damage,
            remaining_ticks,
            projectile_type,
            status,
            last_attacked_player_id,
            pierce,
            skill_name,
        }
    }
    pub fn move_or_explode_if_out_of_board(&mut self, board_height: usize, board_width: usize) {
        self.prev_position = self.position.clone();
        self.position = game::new_entity_position(
            board_height,
            board_width,
            self.direction.x,
            self.direction.y,
            self.position,
            self.speed as i64,
        );

        let direction_x = (self.direction.x * 100f32) as i16;
        let direction_y = (self.direction.y * 100f32) as i16;

        // Next the left wall and moving to the left
        if Projectile::needs_to_explode(
            self.prev_position.x == self.position.x,
            self.prev_position.x == 0,
            direction_y > 0,
        ) {
            self.status = ProjectileStatus::EXPLODED;
        }

        // Next the right wall and moving to the right
        if Projectile::needs_to_explode(
            self.prev_position.x == self.position.x,
            self.prev_position.x == board_height - 1,
            direction_y < 0,
        ) {
            self.status = ProjectileStatus::EXPLODED;
        }

        // Next the up wall and moving to the up
        if Projectile::needs_to_explode(
            self.prev_position.y == self.position.y,
            self.prev_position.y == 0,
            direction_x < 0,
        ) {
            self.status = ProjectileStatus::EXPLODED;
        }

        // Next the down wall and moving to the down
        if Projectile::needs_to_explode(
            self.prev_position.y == self.position.y,
            self.prev_position.y == board_height - 1,
            direction_x > 0,
        ) {
            self.status = ProjectileStatus::EXPLODED;
        }
    }

    pub fn needs_to_explode(eq_coordinates: bool, is_in_wall: bool, moving_to_wall: bool) -> bool {
        return eq_coordinates && is_in_wall && moving_to_wall;
    }
}
