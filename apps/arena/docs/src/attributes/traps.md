# Traps attributes

## Non-changeable attributes

- `id` Unique identifier for the projectile
- `category` The category of this entity
- `name` Name of the trap used to instantiate it
- `position` Position of the trap
- `direction` The angle where the trap is facing
- `speed` The speed of the trap
- `shape` The shape of the trap, at the moment is not editable.
- `mechanics` The mechanics which the trap has
- `owner_id` the ID of the player who owns the trap.
- `preparation_delay_ms` The amount of time in milliseconds to wait until the trap is available to be triggered
- `activation_delay_ms` After the trap gets triggered, this is the time in milliseconds until the trap activates its mechanic.
- `activate_on_proximity` A boolean that determines whether a trap is activated when someone walks near it or just by time.

## Changeable attributes

- `status` Changes depending on the status of the trap, could be one of the following statuses:
    - PENDING: The trap is waiting to be set, depends on the field `preparation_delay_ms`
    - PREPARED: The trap is waiting to be triggered
    - TRIGGERED: The trap is already triggered and is going to use activate its mechanic. Depends on the fields `activation_delay_ms` and `activate_on_proximity`
    - USED: This status is set once the finished its operations/mechanics. This status led us delete the trap from the game state
