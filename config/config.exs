# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

##########################
# General configurations #
##########################

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  game_client: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../apps/game_client/assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.3.2",
  game_client: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../apps/game_client/assets", __DIR__)
  ]

############################
# App configuration: arena #
############################

# Configures the endpoint
dispatch = [
  _: [
    {"/play/:game_id/:client_id", Arena.GameSocketHandler, []},
    {"/join/:client_id/:character_name/:player_name", Arena.SocketHandler, []},
    {:_, Plug.Cowboy.Handler, {ArenaWeb.Endpoint, []}}
  ]
]

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

################################
# App configuration: champions #
################################

###################################
# App configuration: game_backend #
###################################

config :game_backend,
  ecto_repos: [GameBackend.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configure your database
config :game_backend, GameBackend.Repo,
  username: System.get_env("DB_USERNAME"),
  password: System.get_env("DB_PASSWORD"),
  hostname: System.get_env("DB_HOSTNAME"),
  database: System.get_env("DB_NAME"),
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# Configures Ecto migrations
config :game_backend, GameBackend.Repo, migration_primary_key: [type: :binary_id]

##################################
# App configuration: game_client #
##################################

# Configures the endpoint
config :game_client, GameClientWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  render_errors: [
    formats: [html: GameClientWeb.ErrorHTML, json: GameClientWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: GameClient.PubSub,
  live_view: [signing_salt: "XED/NEZq"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :game_client, GameClient.Mailer, adapter: Swoosh.Adapters.Local

##############################
# App configuration: gateway #
##############################
config :gateway,
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
dispatch = [
  _: [
    # {"/1", Gateway.CurseSocketHandler, []},
    {"/2", Gateway.ChampionsSocketHandler, []},
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
  http: [ip: {127, 0, 0, 1}, port: 4001, dispatch: dispatch],
  server: true

############################
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
