import Config

##########################
# General configurations #
##########################

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

############################
# App configuration: arena #
############################

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :arena, ArenaWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "QK4nHna6CWP5+KH2khYXzdIAM2GmQ1B7xwDP6fdjhQro1659xfFvC+69Joj/dKyw",
  server: false

# In test we don't send emails.
config :arena, Arena.Mailer, adapter: Swoosh.Adapters.Test

################################
# App configuration: champions #
################################

###################################
# App configuration: game_backend #
###################################

# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :game_backend, GameBackend.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "game_backend_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

##################################
# App configuration: game_client #
##################################

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :game_client, GameClientWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "QK4nHna6CWP5+KH2khYXzdIAM2GmQ1B7xwDP6fdjhQro1659xfFvC+69Joj/dKyw",
  server: false

# In test we don't send emails.
config :game_client, GameClient.Mailer, adapter: Swoosh.Adapters.Test

##############################
# App configuration: gateway #
##############################

###################################
# App configuration: configurator #
###################################

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :configurator, Configurator.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "configurator_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :configurator, ConfiguratorWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "VD24DNfwxloA29uofA2lhyx0yMQ48/uwJJsoUHksnksuEk5AcV4C+jNmxkQeP7f8",
  server: false

# In test we don't send emails.
config :configurator, Configurator.Mailer, adapter: Swoosh.Adapters.Test
