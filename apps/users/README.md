# Users

The Users application defines utilites for interacting with Users, that are common across all games. Also defines the data structures themselves. Operations that can be done to a User are:
- Create

For now, users consist of only a username. No authentication of any sort has been implemented.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `users` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:users, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/users>.
