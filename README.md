# Lambda Game Backend
Open source backend developed by LambdaClass in Elixir, for the communication, and Rust, for the state management.

## Table of Contents

- [Lambda Game Backend](#lambda-game-backend)
  - [Table of Contents](#table-of-contents)
  - [Documentation](#documentation)
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

## Running the Backend

### Requirements

- Rust >= 1.72.0
- Erlang OTP >= 26
- Elixir >= 1.15.4
- Docker and docker compose
- [inotify-utils](https://hexdocs.pm/phoenix/installation.html#inotify-tools-for-linux-users) if using Linux (optional, for development live reload)

Ensure Docker is running and then...

Install protobuf dependency:
  - ```brew install protobuf``` (MacOS)
  - ```mix escript.install hex protobuf```

If you wanna test the backend in the browser, then install protobuf-javascript dependency:
  - ```cd assets```
  - ```npm install google-protobuf```
  - ```npm install -g protoc-gen-js```

Start phoenix server using:
  - ```make deps```
  - ```make start```

## Contributing
