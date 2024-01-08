# Loots

## Configuration

Configurable fields:
- `name`: unique name for the loot, this will be referenced by other configurations
- `size`: radius size of the loot
- `pickup_mechanic`: Defines how the loot is picked up, see ["Pickup mechanics"](#pickup-mechanics)
- `effects`: List of effects the loot will give out

## Pickup mechanics

- `CollisionToInventory`: On colliding with the loot it will be stored in the user inventory if there is space
- `CollisionUse`: On colliding with the loot it will be applied to the colliding player

### Example

```
[
  {
    "name": "giant"
    "size": 100,
    "effects": ["gigantify"]
  },
  {
    "name": "heal"
    "size": 100,
    "effects": ["gain_health_10_3s"]
  }
]
```
