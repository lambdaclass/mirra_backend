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
  ],
  configurator: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../apps/configurator/assets", __DIR__),
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
  ],
  configurator: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../apps/configurator/assets", __DIR__)
  ]

config :ueberauth, Ueberauth,
  providers: [
    google: {Ueberauth.Strategy.Google, []}
  ]

############################
# App configuration: arena #
############################

# Configures the endpoint
dispatch = [
  _: [
    {"/play/:game_id/:client_id", Arena.GameSocketHandler, []},
    {"/join/:client_id/:character_name/:player_name", Arena.SocketHandler, []},
    {"/quick_game/:client_id/:character_name/:player_name", Arena.QuickGameHandler, []},
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

# Amount of clients needed to start a game
config :arena, :players_needed_in_match, 10

################################
# App configuration: champions #
################################

###################################
# App configuration: game_backend #
###################################

config :game_backend,
  ecto_repos: [GameBackend.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures Ecto migrations
config :game_backend, GameBackend.Repo, migration_primary_key: [type: :binary_id]

{:ok, currency_config_json} =
  Application.app_dir(:game_backend, "priv/currencies_rules.json")
  |> File.read()

config :game_backend, :currencies_config, Jason.decode!(currency_config_json)

##################################
# App configuration: game_client #
##################################

# Configures the endpoint
config :game_client, GameClientWeb.Endpoint,
  url: [host: "localhost", port: 4002],
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

###################################
# App configuration: configurator #
###################################
config :configurator,
  ecto_repos: [Configurator.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :configurator, ConfiguratorWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: ConfiguratorWeb.ErrorHTML, json: ConfiguratorWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Configurator.PubSub,
  live_view: [signing_salt: "6A8twvHJ"]

############################
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
