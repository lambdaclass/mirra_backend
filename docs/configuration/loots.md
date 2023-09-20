# Loots

## Configuration

Configurable fields:
- `name`: unique name for the loot, this will be referenced by other configurations
- `size`: radius size of the loot
- `effects`: List of effects the loot will give out

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
