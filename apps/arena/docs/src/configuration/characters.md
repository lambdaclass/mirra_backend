# Characters

## Configuration

Configurable fields:
- `name`: Unique name of the character, this will be referenced by other configurations
- `active`: Can the character be picked
- `base_speed`: Base speed of the character
- `base_size`: Size of the character for collision math
- `base_health`: Base health of the character
- `skills`: This is a map of integer (as string) to skills, the integers represent the id and ordering of skills for calling them
- `max_inventory_size`: Maximum amount of loots that the character can hold in their inventory

### Example

```
[
  {
    "name": "H4ck"
    "active": true,
    "base_speed": 25,
    "base_size": 80,
    "base_health": 8000,
    "skills": {
      "1": "Slingshot",
      "2": "Multishot",
    }

  }
]
```

# Units

Units are instances of characters tied to a user. Depending on the game, a user may have up to one or unlimited units of the same character. These also hold additional information like their level, slot, or if they are selected. For cases when a user has only one unit for each character, the unit's level may indicate their prowess with them.
