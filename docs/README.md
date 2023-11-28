# Documentation

* [Configuration](#configuration)
  * [Effects](./configuration/effects.md)
  * [Loots](./configuration/loots.md)
  * [Projectiles](./configuration/projectiles.md)
  * [Skills](./configuration/skills.md)
  * [Characters](./configuration/characters.md)
  * [Game](./configuration/game.md)
* [Attributes](#attributes)
  * [Player attributes](./attributes/players.md)
  * [Projectile attributes](./attributes/projectiles.md)
* [Metrics and monitoring](./metrics_and_monitoring/metrics-and-monitoring.md)
* [Load Testing](./load_testing/load_testing.md)

## Configuration

The game can be configured through a JSON file which is passed on initiation of a game. High level looks like

```
{
  "effects": [...]
  "loots": [...]
  "projectiles": [...]
  "skills": [...]
  "characters": [...]
  "game": [...]
}
```

Read more about each field
- [Effects](./configuration/effects.md)
- [Loots](./configuration/loots.md)
- [Projectiles](./configuration/projectiles.md)
- [Skills](./configuration/skills.md)
- [Characters](./configuration/characters.md)
- [Game](./configuration/game.md)

## Attributes

All in-game entities have a set of attributes (fields in a Rust struct), this attributes represents everything of the entity.

This attributes represent part of the API offered by the game backend, you might have access to more attributes, but using them is at your own risk

Each attribute will fall in one of two categories
- `Non-changeable`: This means the attribute is set by the game backend and either completely static or only modified through calls to its API and in-game logic
- `Changeable`: This attributes can be modified by effects, see [Effects Configuration: Attributes changes](../configuration/effects.md) for more information on how this happens

Read more about each entity attributes
- [Player attributes](./attributes/players.md)
- [Projectile attributes](./attributes/projectiles.md)
