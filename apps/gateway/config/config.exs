# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :gateway,
  generators: [timestamp_type: :utc_datetime]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configures the endpoint
dispatch = [
  _: [
    # {"/1", Gateway.CurseSocketHandler, []},
    {"/2/:client_id", Gateway.ChampionsSocketHandler, []},
    {:_, Plug.Cowboy.Handler, {Gateway.Endpoint, []}}
  ]
]

# Configures the endpoint
config :gateway, Gateway.Endpoint,
  url: [host: "localhost", port: 4001],
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  render_errors: [
    formats: [json: Gateway.ErrorJSON],
    layout: false
  ],
  pubsub_server: Gateway.PubSub,
  live_view: [signing_salt: "XED/NEZq"],
  http: [ip: {127, 0, 0, 1}, port: 4001, dispatch: dispatch]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
