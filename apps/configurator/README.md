# Configurator

This app is in charge of the configurations. Think either full game config or feature flags for A/B testing

In it you will be able to create new configurations and decide the default version to be used. Configurations are inmutable to allow rollbacks and easier A/B testing, you can always create a new one based on the default one or one in particular

To run in development you can either run it through the umbrella root or in the app repo by doing either `mix phx.server` or `iex -S mix phx.server`

## Web UI

You can visit this in [`localhost:4100`](http://localhost:4100).

In there you will be able to do the following:
- See, create, edit character configurations.

Next steps:
- Do the same for other configurations (game, skills, etc.).
- See all configurations and which one is the default.
- See details of a specific configuration version.
- Create a new configuration, either based on the default one or from another.
- Change default configuration.
