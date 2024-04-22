# Power ups

The power ups are entities droped when a player dies that can be picked up for players and modify how strong a player is 

## Configuration

- `power_ups_per_kill`: Defines how many power ups a player will drop when it dies
- `minimum_amount`: Defines the minimum amount of power up a player needs to have to drop that amount of power ups
- `amount_of_drops`: How many power ups a player will drop when it dies with certain amount of power ups
- `power_up`: Determines the specs of the power up that will be dropped
- `distance_to_power_up`: Distance from the position where the player dies to where the power up will be, it'll spawn in a random direction
- `power_up_damage_modifier`: How much additional damage the power up will provide
- `power_up_health_modifier`: How much additional health the power up will provide
- `radius`: The radius of pickup of the power up



## Example 

...
  {
    "power_ups_per_kill": [
      {"minimum_amount": 0, "amount_of_drops": 1},
      {"minimum_amount": 2, "amount_of_drops": 2},
    ],
    "power_up": {
      "distance_to_power_up": 500,
      "power_up_damage_modifier": 0.10,
      "power_up_health_modifier": 0.10,
      "radius": 10.0
    }
  }
...
