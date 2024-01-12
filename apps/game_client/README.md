# Game Client

Web client in browser for 2D Games. Developed in Elixir and Phoenix framework.

## Table of Contents

- [Game Client](#game-client)
  - [Table of Contents](#table-of-contents)
  - [Running the Client](#running-the-client)
    - [Requirements](#requirements)
  - [Contributing](#contributing)

Open: [http://localhost:3000/](http://localhost:3000/)

## Running the Client

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
