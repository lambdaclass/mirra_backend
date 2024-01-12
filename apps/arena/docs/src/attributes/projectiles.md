# Projectile attributes

## Non-changeable attributes

- `id`: Unique identifier for the projectile
- `name`: Name of the projectile config used to instantiate
- `character`: Character projectile is using
- `on_hit_effects`: Effects given to target on collision
- `position`: Current position
- `direction`: Angle where the projectile is facing
- `creator_player_id`: ID of the player that created the projectile
- `duration_ms`: Time remaining on the projectile
- `distance`: Distance remaining on the projectile

## Changeable attributes

- `damage`: Damage done to players on collision
- `speed`: Speed of the projectile
- `size`: Size for the projectile model and collision math
- `remove_on_collision`: Determines if the projectile is removed from game after colliding with a player
