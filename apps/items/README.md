# Items

The Items application defines utilites for interacting with Items, that are common across all games. Also defines the data structures themselves. Operations that can be done to an Item are:
- Create
- Equip to a unit
- Level up

Items are created by instantiating copies of ItemTemplates. This way, many users can have their own copy of the "Epic Sword" item. Likewise, this allows for a user to have many copies of it, each with their own level and equipped to a different unit.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `items` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:items, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/items>.
