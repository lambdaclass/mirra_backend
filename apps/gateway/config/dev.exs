import Config

# Configure your database
config :gateway, Gateway.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "game_backend_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :gateway, GatewayWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "0zq8I9ztj7kj4cLdFmvduHwXQJJi9yzNUAUFAlKHkdXS/nJkxUvNPjlSdJPDSUf5"
