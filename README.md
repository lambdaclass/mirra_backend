# Lambda Game Backend
Open source backend developed by LambdaClass in Elixir, for the communication, and Rust, for the state management.

## Documentation

You can find our documentation in [docs](./docs/README.md) folder, or run it locally

To run locally, install:

```
cargo install mdbook
cargo install mdbook-mermaid
```

Then run:

```
make docs
```

Open: [http://localhost:3000/](http://localhost:3000/)

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

## Contributing

### Requirements

- Rust >= 1.72.0
- Erlang OTP >= 26
- Elixir >= 1.15.4
