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
