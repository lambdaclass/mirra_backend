# Configurator

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix

# Configurator

This app is in charge of the configurations. Think either full game config or feature flags for A/B testing

In it you will be able to create new configurations and decide the default version to be used. Configurations are inmutable to allow rollbacks and easier A/B testing, you can always create a new one based on the default one or one in particular

To run in development you can either run it through the umbrella root or in the app repo by doing either `mix phx.server` or `iex -S mix phx.server`

The app offers 2 interfaces, a web UI and a JSON API

## Web UI

You can visit this in [`localhost:4100`](http://localhost:4100) (either `/` or `/configurations`). In there you will be able to do the following
- See all configurations and which one is the default
- See detatils of a specific configuration version
- Create a new configuration, either based on the default one or from another
- Change default configuration

## JSON API

The API offers 2 endpoints

- `/api/default_config` Fetches the default configuration version
- `/configurations/:id` Fetches a specific configuration version


## Current State

The current state of the Configurator app has the following features:
- Version control system: We have records of past configurations and we can set a specific version as the current one.
- UI that only allows users to edit Champions of Mirra configurations.
  - Users can only edit these JSON files in plain text, specifically through an HTML textbox.
- Endpoints to retrieve the default configuration and a specific one.

## Features and Refactor

### First Iteration

- Implement a UI to display our current JSONs from Champions of Mirra and AFK Gacha Game.
- Allow users to modify these JSONs and store them in the database.

### Second Iteration

- Create or modify current endpoints to retrieve configurations for both games.
- Refactor the games (Champions of Mirra and AFK Gacha Game) to get the config from these new endpoints.

### Third Iteration

- Google Sign-in and Sign-up.
  - These users will be different from the actual game users.
  - Only allow LambdaClass domains.
- Store in the database who created or edited a particular configuration.

### Fourth Iteration

- Feature to create new fields in a particular configuration.
- Feature to create new JSONs.

### Fifth Iteration

- UI/UX improvements (TBD).
