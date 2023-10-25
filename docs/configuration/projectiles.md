# Projectiles

## Configuration

Configurable fields:
- `name`: Unique name for the projectile, this will be referenced by other configurations
- `base_damage`: Damage done by the projectile on collision
- `base_speed`: Travel speed of the projectile
- `base_size`: Size of the projectile for collision math
- `pierce`: Determines if the projectile is removed from game after colliding with a player, default is `true`
- `on_hit_effects`: Effects given to target on collision
- `duration_ms`: Defines how long in milliseconds the projectile can exist
- `max_distance`: Defines the maximum distance the projectile can travel

**Note:** If both `duration_ms` and `max_distance` are specified it will trigger on whichever it reaches first, it won't wait for both

### Example

Some example configurations

```
[
  {
    "name": "some_projectile",
    "base_damage": 10,
    "base_speed": 123,
    "base_size": 50,
    "pierce": false,
    "on_hit_effects": []
  },
  {
    "name": "poison_dart"
    "base_damage": 25,
    "base_speed": 70,
    "base_size": 50,
    "on_hit_effect": ["poison"],
    "max_distance": 1200
  },
  {
    "name": "poison_dart"
    "base_damage": 0,
    "base_speed": 120,
    "base_size": 50,
    "on_hit_effect": ["freeze"],
    "duration_ms": 2000
  },
]
```
