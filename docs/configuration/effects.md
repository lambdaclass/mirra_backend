# Effects

Effects are mostly buffs and debuffs players can have. They will given by skills or loot.

## Configuration

Configurable fields:
- `name`: unique name for the effect, this will be referenced by other configurations
- `effect_time_type`: This determines how the effect is applied, see below ["Effect time type"](#effect-time-type)
- `is_reversable`: Defines if the effect can be reversed when removed from the player (e.g. if it gives 10% more speed it will be removed from the player on removal), see more in ["Adding and removing effects"](#adding-and-removing-effects)
- `player_attributes`: Attributes changes that will be applied over the player having this effect
- `projectile_attributes`: Attributes changes that will be applied over the projectiles of the player having this effect

### Effect time type

It can be any of:
- `Instant`: Effect is executed once and removed
- `Duration`: Effect is stuck on the player for a duration
  - `duration_ms`
- `Permanent`: Effect lasts forever and can only be removed by other effects
- `Periodic`: Like an Instant, but the effect is applied many times over a period of time
  - `instant_application`: Boolean specifying if first application of effect should happen at instant 0 or not
  - `interval_ms`: Every X milliseconds the effect will be applied
  - `trigger_count`: Sets how many times the effect will be applied

For `Duration` and `Periodic` the configuration expects a JSON object with a `type` field corresponding to the type

```
{
  "type": "Duration",
  "duration_ms": 1234
}

{
  "type": "Periodic",
  "instant_application": false
  "interval_ms": 500
  "trigger_count": 4
}
```


### Attributes changes

To learn more about attributes see the [Attributes](../attributes/attributes.md) section, below you can find quick links to the documentation for each entity with changeable attributes

- [Player attributes](../attributes/players.md)
- [Projectile attributes]()

An attribute change is comprised of the following:
- `attribute`: Attribute to modify, the exact values allowed depend on the entity you are modifying. If the attribute is a map you can either provide the attribute to modify all or use `.` syntax to only target a key in it
- `modifier`: Determines how `value` interacts with the current value of the attribute, it can be one of
  - `additive`: Given value is added to current value
  - `multiplicative`: Given value is multiplied to current value
  - `override`: Given value is set as the attribute value
- `value`: The value we are using for the change

```
# Heal by 20%
{
  "attribute": "Health",
  "modifier": multiplicative,
  "value": 1.2
}
```

### Example

Examples of the JSON defining effects

```
[
  {
    "name": "gain_health_10_3s"
    "is_reversable": false,
    "effect_time_type": {
      "type": "Periodic",
      "instant_application": false
      "interval_ms": 1000
      "trigger_count": 3
    },
    "player_attributes: [
      {
        "attribute": "Health",
        "modifier": additive,
        "value": 10
      }
    ]
  },
  {
    "name": "gigantify"
    "effect_time_type": {
      "type": "Duration",
      "duration_ms": 5000
    },
    "player_attributes: [
      {
        "attribute": "Size",
        "modifier": multiplicative,
        "value": 1.5
      },
      {
        "attribute": "Damage",
        "modifier": additive,
        "value": 20
      }
    ]
  }
]
```

### Adding and removing effects

Some effects result in an increase in a player's attributes. When the effect's duration expires, we need to revert the changes made to the attribute. To address this, we've implemented a revert_attribute function that undoes the effect's modifications.

However, caution is required! With the possibility of applying both Additive and Multiplicative effects, there is a risk of not obtaining the correct attribute values when performing a reversal.

Furthermore, we haven't accounted for the ability to reverse an Override effect since we don't store the previous value.

### Examples
```
These example is a supposition.

Suppose a player has an initial speed of 100 units. The player acquires boots that boost their speed by 50% (multiplicative (*1.5)). Then, they receive a leap, which reduces their speed by 10 units (additive (-10)). After these two events, the player has a speed of 140 units.

If we reverse the effects in the following order, we will return to the original value of 100:

1. Add 10 units to the speed value (reverse additive + 10).
2. Divide the value by 1.5 (reverse multiplicative / 1.5).

However, if we change the order as follows:

1. Divide the value by 1.5 (reverse multiplicative / 1.5).
2. Add 10 units to the speed value (reverse additive + 10).

We will obtain the wrong value of 103.
```
