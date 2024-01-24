import Config

# Configure your database
config :champions_of_mirra, ChampionsOfMirra.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "champions_of_mirra_dev",
  port: 5433,
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"
