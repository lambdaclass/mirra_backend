# Attributes

All in-game entities have a set of attributes (fields in a Rust struct), this attributes represents everything of the entity.

This attributes represent part of the API offered by the game backend, you might have access to more attributes, but using them is at your own risk

Each attribute will fall in one of two categories
- `Non-changeable`: This means the attribute is set by the game backend and either completely static or only modified through calls to its API and in-game logic
- `Changeable`: This attributes can be modified by effects, see [Effects Configuration: Attributes changes](../configuration/effects.md) for more information on how this happens

Read more about each entity attributes:
- [Player attributes](./attributes/players.md)
- [Projectile attributes](./attributes/projectiles.md)
