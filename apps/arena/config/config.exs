# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Configures the endpoint
dispatch = [
  _: [
    {"/play/:game_id/:player_id", Arena.GameSocketHandler, []},
    {"/play/:player_id", Arena.SocketHandler, []},
    {:_, Plug.Cowboy.Handler, {ArenaWeb.Endpoint, []}}
  ]
]

config :arena,
  ecto_repos: [Arena.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :arena, ArenaWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  render_errors: [
    formats: [html: ArenaWeb.ErrorHTML, json: ArenaWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Arena.PubSub,
  live_view: [signing_salt: "XED/NEZq"],
  http: [dispatch: dispatch]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :arena, Arena.Mailer, adapter: Swoosh.Adapters.Local

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
