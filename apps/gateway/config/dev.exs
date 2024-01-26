import Config

config :gateway, GatewayWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {127, 0, 0, 1}, port: 4001],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "0zq8I9ztj7kj4cLdFmvduHwXQJJi9yzNUAUFAlKHkdXS/nJkxUvNPjlSdJPDSUf5"
