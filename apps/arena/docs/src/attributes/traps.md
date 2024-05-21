# Trap Attributes

## Non-Changeable Attributes

- `id`: Unique identifier for the trap
- `category`: The category of this entity
- `name`: Name of the trap used to instantiate it
- `position`: Position of the trap
- `direction`: The angle where the trap is facing
- `speed`: The speed of the trap
- `shape`: The shape of the trap, which is currently not editable
- `mechanics`: The mechanics of the trap
- `owner_id`: The ID of the player who owns the trap
- `preparation_delay_ms`: The amount of time in milliseconds to wait until the trap is available to be triggered
- `activation_delay_ms`: The time in milliseconds after the trap gets triggered until it activates its mechanic
- `activate_on_proximity`: A boolean that determines whether the trap is activated when someone walks near it or just by time

## Changeable Attributes

- `status`: Changes depending on the status of the trap and can be one of the following:
  - `PENDING`: The trap is waiting to be set, depending on the field `preparation_delay_ms`
  - `PREPARED`: The trap is waiting to be triggered
  - `TRIGGERED`: The trap is already triggered and is going to activate its mechanic, depending on the fields `activation_delay_ms` and `activate_on_proximity`
  - `USED`: This status is set once the trap has finished its operations/mechanics, indicating it can be deleted from the game state


## Example

```json
{
  "name": "bomb",
  "radius": 200.0,
  "activation_delay_ms": 3000,
  "preparation_delay_ms": 3000,
  "activate_on_proximity": true,
  "vertices": [],
  "mechanics": {
    "circle_hit": {
      "damage": 64,
      "range": 380.0,
      "offset": 400
    }
  }
}
```
