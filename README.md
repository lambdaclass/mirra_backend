# Lambda Game Backend
Open source backend developed by LambdaClass in Elixir, for the communication, and Rust, for the state management.

## Table of Contents

- [Lambda Game Backend](#lambda-game-backend)
  - [Table of Contents](#table-of-contents)
  - [Documentation](#documentation)
  - [Installation](#installation)
  - [Running the Backend](#running-the-backend)
    - [Requirements](#requirements)
  - [Contributing](#contributing)


## Documentation

You can find our documentation in [docs](./docs/src/README.md) folder, or run it locally.

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

## Running the Backend

### Requirements

- Rust >= 1.72.0
- Erlang OTP >= 26
- Elixir >= 1.15.4
- Docker and docker compose
- [inotify-utils](https://hexdocs.pm/phoenix/installation.html#inotify-tools-for-linux-users) if using Linux (optional, for development live reload)

Ensure Docker is running and execute:

```bash
git clone https://github.com/lambdaclass/game_backend
make db
make setup
make start
```

Whenever you make changes to the game's `config.json`, you will need to run this so that they get reflected:

```elixir
DarkWorldsServer.Utils.Config.clean_import()
```

## Contributing
