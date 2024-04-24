# GameBackend

Application for the Game Backend. Implements persistance layer for:

- Campaigns
  - Levels
  - Rewards
  - Progression
- Items
  - Item Templates
- Units
  - Characters
    - Skills
- Users
  - Currencies
  - AFK Rewards
- Gacha

## Class Diagram

![GameBackend class diagram](/apps/game_backend/docs/game_backend_classes.png "GameBackend class diagram")

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `game_backend` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:game_backend, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/game_backend>.
