import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :dark_worlds_server, DarkWorldsServer.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "dark_worlds_server_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :dark_worlds_server, DarkWorldsServerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "Qu1oU8AKEU4oxh5vqy6daXy8evjMwFiwr52p1MBv2I56bjeyFtCWKyJ3L/9u6NDK",
  server: true

config :dark_worlds_server,
  config_folder: "../client/Assets/StreamingAssets/"

# In test we don't send emails.
config :dark_worlds_server, DarkWorldsServer.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
