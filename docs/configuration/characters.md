# Characters

## Configuration

Configurable fields:
- `name`: Unique name of the character, this will be referenced by other configurations
- `active`: Can the character be picked
- `base_speed`: Base speed of the character
- `base_size`: Size of the character for collision math
- `base_health`: Base health of the character
- `skills`: This is a map of integer (as string) to skills, the integers represent the id and ordering of skills for calling them

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
