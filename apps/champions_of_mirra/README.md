# Curse Of Mirra

Application for the Champions Of Mirra game. Implements modules for:

- Battle: Simulates battles. For now, only allows fights between a user and a level from the campaign. Battle outcome is affected by the level of units and equipped items of each team.
- Campaigns: Creates a campaign with customizable difficulty, in the shape of 5 units per level.
- Items: Handles logic for Items. Items are owned by a user and can be equipped to units to enhance their level in battle. They can also be leveled up at a scaling gold price.
- Units: Handles logic for Units. Units are owned by a user and can be selected to fight in the user's lineup.
- Users: Handles logic for Users.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `curse_of_mirra` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:curse_of_mirra, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/curse_of_mirra>.
