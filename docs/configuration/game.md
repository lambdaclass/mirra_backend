# Game

This is the meta configuration for the game, not for a particular thing in the game

## Configuration

- `width`: Defines the width of the playing area
- `height`: Defines the length of the playing area
- `map_modification`: If present, contains the information for when the map modification mechanic is triggered, see below [Map modification](#map-modification)
- `loot_interval_ms`: If present, interval in milliseconds for spawning loot crates

### Map modification

- `modification`: Defines how to modify the playable area radius, similar to attributes changes it has a `modifier` and `value` fields
- `starting_radius`: Starting radius for the playable area
- `minimum_radius`: Mininum radius for the playable area, how small can the playable zone get
- `max_radius`: Max radius for the playable area, how big can the playable zone get
- `outside_radius_effects`: Effects given when a player is outside the playable area
- `inside_radius_effects`: Effects given when a player is inside the playable area

### Example

```
{
  "width": 10000,
  "height": 10000,
  "map_modification": {
    "modification": {
      "modifier": "Multiplicative",
      "value": 0.9,
    },
    "starting_radius": 10000,
    "minimum_radius": 1800,
    "max_radius": 10000,
    "outside_radius_effects": [],
    "inside_radius_effects": ["damage_outside_area"]
  }
  "loot_interval_ms": 7000
}
```
