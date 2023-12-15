# Skills

## Configuration

- `name`: Unique name for the skill, this will be referenced by other configurations
- `cooldown_ms`: Time that needs to elapse before the skill recharges
- `execution_duration_ms`: Time in milliseconds it takes to perform the skill, player will be unable to move or attack in the meantime
- `is_passive`: Marks the skill as a passive skill, this means it can't be triggered. Instead it will trigger on player spawn, so only `GiveEffect` makes sense for it
- `mechanics`: Core mechanic of the skill (e.g hit, shoot, etc)

### Mechanics

These are the mechanics so far. Every mechanic will add a configuration field with the same name, which is a nested object with configuration attributes specific for it

- `GiveEffect`: This makes the skill give a certain effect
  * `effects`: List of effects given
- `Hit`: Player will hit all things in area of target
  * `damage`: Damage done to targets
  * `range`: Up to how far away can things be hit
  * `cone_angle`: Defines how the cone of hit is generated, see [Explaining cone_angle](#explaining-cone_angle)
  * `on_hit_effects`: Effects given to targets hit by skill
- `SimpleShoot`: Player will shoot a projectile
  * `projectile`: Projectile to shoot
- `MultiShoot`: Player will shoot multiple shots of a projectile
  * `projectile`: Projectile to shoot
  * `count`: How many projectiles will be shot
  * `cone_angle`: Defines how wide is the angle to spread the projectiles on, see [Explaining cone_angle](#explaining-cone_angle)
- `MoveToTarget`: Player will be moved to target position
  * `duration_ms`: How long it takes to move the player, 0 means instantly
  * `max_range`: Maximum distance allowed to move, if target is beyond this limit movement will be capped to this point

### Explaining cone_angle

`cone_angle` is the angle to define a cone coming from a player, this is mostly used to define an area from where targets can be selected.

This angle takes the player orientation as angle 0, so for simplicit let's say orientation is 0 as well. As the angle increases the cone starts to open, this cone is formed so if the angle is 90˚ doesn't mean it goes from orientation 0 to 90, it actually means it goes from orientation 45 to -45. The cone opens equally on both ways. Something like this

```
o o o o x     Legend:
o o o x x       `>` is the player, it is looking to the right (east)
o o > x x       `o` represents spaces not selected for targetting
o o o x x       `x` represents spaces selected for targetting
o o o o x
```

This means that an angle of 180˚ would pick everything from the sides to the front of the player, but not the back. Something like this

```
o o x x x     Legend:
o o x x x       `>` is the player, it is looking to the right (east)
o o > x x       `o` represents spaces not selected for targetting
o o x x x       `x` represents spaces selected for targetting
o o x x x
```

## Configuration

Some example configurations

```
[
  {
    "name": "rage"
    "cooldown_ms": 10000,
    "is_passive": false,
    "mechanics": [
      {
        "GiveEffect": {
          "effects": ["damage_increase_45", "speed_increase_25"]
        }
      }
    ]
  },
  {
    "name": "5_shot"
    "cooldown_ms": 4500,
    "is_passive": false,
    "mechanics": [
      {
        "Shoot": {
          "projectile": "some_projectile"
          "multishot_count": 5
          "multishot_cone_angle": 90
        }
      }
    ]
  },
  {
    "name": "leap"
    "cooldown_ms": 6000,
    "is_passive": false,
    "mechanics": [
      {
        "MoveToTarget": {
          "duration_ms": 1000
          "max_range": 500
        }
      },
      "Hit": {
        "damage": 25
        "range": 100
        "cone_angle": 360
      }
    ],
  }
]
```
