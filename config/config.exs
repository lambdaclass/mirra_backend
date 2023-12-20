# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :dark_worlds_server,
  ecto_repos: [DarkWorldsServer.Repo]

config :dark_worlds_server, DarkWorldsServer.Repo, migration_primary_key: [type: :binary_id]

# Configures the endpoint
dispatch = [
  _: [
    {"/play/:game_id/:client_id/:selected_character", DarkWorldsServerWeb.PlayWebSocket, []},
    {"/matchmaking", DarkWorldsServerWeb.LobbyWebsocket, []},
    {:_, Plug.Cowboy.Handler, {DarkWorldsServerWeb.Endpoint, []}}
  ]
]

config :dark_worlds_server, DarkWorldsServerWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [json: DarkWorldsServerWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: DarkWorldsServer.PubSub,
  live_view: [signing_salt: "HPijD5SN"],
  http: [dispatch: dispatch]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :dark_worlds_server, DarkWorldsServer.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(css/game.css js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/* --external:/game/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.2.7",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/css/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configures game GenServer
config :dark_worlds_server, DarkWorldsServer.RunnerSupervisor.Runner, process_priority: :high

# Configure server hash
{hash, _} = System.cmd("git", ["rev-parse", "--short=8", "HEAD"])
hash = String.trim(hash)
config :dark_worlds_server, :information, version_hash: hash

# By default disable NewRelic agent
config :new_relic_agent, license_key: nil

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
