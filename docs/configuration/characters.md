# Characters

## Configuration

Configurable fields:
- `name`: Unique name of the character, this will be referenced by other configurations
- `active`: Can the character be picked
- `base_speed`: Base speed of the character
- `base_size`: Size of the character for collision math
- `skills`: This is a map of integer (as string) to skills, the integers represent the id and ordering of skills for calling them

### Example

```
[
  {
    "name": "H4ck"
    "active": true,
    "base_speed": 25,
    "base_size": 80,
    "skills": {
      "1": "Slingshot",
      "2": "Multishot",
      "3": "Disarm",
      "4": "Neon Crash",
      "5": "Denial of Service",
    }

  }
]
```
