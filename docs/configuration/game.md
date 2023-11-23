# Game

This is the meta configuration for the game, not for a particular thing in the game

## Configuration

- `width`: Defines the width of the playing area
- `height`: Defines the length of the playing area
- `zone_starting_radius`: Radius of the playable zone. The zone is an area in the map where effects are applied to players not in it
- `zone_modifications`: This is attribute is a list of modifications to perform to the playable zone in the map. For the specifics see below ["Zone modification"](#zone-modification)
- `loot_interval_ms`: If present, interval in milliseconds for spawning loot crates
- `auto_aim_max_distance`: Determines the max distance to auto aim

### Zone modification

As mentioned this attribute is composed of a list of "modifications". These modifications are processed in order and once the `duration_ms` of the current one is reached the runner will move on to the next one and apply changes based on those rules. If you don't wish to have any modifications you can set an empty list

This "modifications" are compose of the following fields

- `duration_ms`: Duration the modification should be applied for
- `modification`: Defines how to modify the playable zone radius, similar to attributes changes it has a `modifier` and `value` fields
- `interval_ms`: Every X milliseconds the modification is applied
- `min_radius`: Mininum radius for the playable zone, how small can the playable zone get
- `max_radius`: Max radius for the playable zone, how big can the playable zone get
- `outside_radius_effects`: Effects given when a player is outside the playable zone

### Example

```
{
  "width": 10000,
  "height": 10000,
  "zone_starting_radius": 10000,
  "zone_modification": [
    {
      "duration_ms": 1000,
      "modification": {
        "modifier": "Multiplicative",
        "value": 0.9,
      },
      "interval_ms": 500,
      "trigger_count": 5000,
      "min_radius": 1800,
      "max_radius": 10000,
      "outside_radius_effects": [damage_outside_area],
    }
  ]
  "loot_interval_ms": 7000,
  "auto_aim_max_distance": 2000,
}
```
