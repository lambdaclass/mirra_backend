# Units

The Units application defines utilites for interacting with Units, that are common across all games. Also defines the data structures themselves. Operations that can be done to a Unit are:
- Create
- Select to a slot/Unselect 

Units are created by instantiating copies of Characters. This way, many users can have their own copy of the "Muflus" character. Likewise, this allows for a user to have many copies of them, each with their own level, selected status and slot.


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `units` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:units, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/units>.
