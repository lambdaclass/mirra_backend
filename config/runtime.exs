import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/arena start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.

##########################
# General configurations #
##########################
config :ueberauth, Ueberauth.Strategy.Google.OAuth,
  client_id: System.get_env("CONFIGURATOR_GOOGLE_CLIENT_ID"),
  client_secret: System.get_env("CONFIGURATOR_GOOGLE_CLIENT_SECRET")

config :joken,
  issuer: "https://accounts.google.com",
  audience: System.get_env("GOOGLE_CLIENT_ID")

if config_env() == :prod do
  jwt_private_key_base64 =
    System.get_env("JWT_PRIVATE_KEY_BASE_64") ||
      raise """
      environment variable JWT_PRIVATE_KEY_BASE_64 is missing
      """

  jwt_private_key = Base.decode64!(jwt_private_key_base64)

  config :joken,
    default_signer: [
      signer_alg: "Ed25519",
      key_openssh: jwt_private_key
    ]
end

############################
# App configuration: arena #
############################

metrics_endpoint_port =
  if System.get_env("METRICS_ENDPOINT_PORT") in [nil, ""] do
    9568
  else
    System.get_env("METRICS_ENDPOINT_PORT") |> String.to_integer()
  end

config :arena, :gateway_url, System.get_env("GATEWAY_URL") || "http://localhost:4001"
config :arena, :metrics_endpoint_port, metrics_endpoint_port

if System.get_env("PHX_SERVER") do
  config :arena, ArenaWeb.Endpoint, server: true
end

if System.get_env("USE_PROXY") do
  ToxiproxyEx.populate!([
    %{
      name: "game_proxy",
      listen: "0.0.0.0:5000",
      upstream: "127.0.0.1:4000"
    }
  ])
end

if config_env() == :prod do
  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "3000")

  config :arena, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :arena, ArenaWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :arena, ArenaWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your endpoint, ensuring
  # no data is ever sent via http, always redirecting to https:
  #
  #     config :arena, ArenaWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :arena, Arena.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney and Finch out of the box:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.
end

################################
# App configuration: champions #
################################

###################################
# App configuration: game_backend #
###################################

if System.get_env("RELEASE") == "central_backend" or config_env() == :dev do
  {:ok, daily_rewards_json} =
    Application.app_dir(:game_backend, "priv/daily_rewards_rules.json")
    |> File.read()

  config :game_backend, :daily_rewards_config, Jason.decode!(daily_rewards_json)

  arena_prestige_ranks_json =
    Application.app_dir(:game_backend, "priv/arena_prestige_ranks.json")
    |> File.read!()
    |> Jason.decode!()

  arena_prestige_ranks =
    Enum.reduce(arena_prestige_ranks_json["ranks"], [], fn rank, acc ->
      Enum.reduce(rank["sub_ranks"], acc, fn sub_rank, acc ->
        entry = %{
          rank: rank["rank"],
          sub_rank: sub_rank["sub_rank"],
          min: sub_rank["min"],
          max: sub_rank["max"]
        }

        [entry | acc]
      end)
    end)
    |> Enum.sort_by(& &1.min, :asc)

  arena_prestige_rewards =
    Enum.reduce(arena_prestige_ranks_json["rewards"], %{}, fn reward, acc ->
      distributions =
        Enum.reduce(reward["distributions"], [], fn distribution, acc ->
          entry = %{
            min: distribution["min"],
            max: distribution["max"],
            reward: distribution["reward"]
          }

          [entry | acc]
        end)
        |> Enum.sort_by(& &1.min, :asc)

      Map.put(acc, reward["position"], distributions)
    end)

  config :game_backend, :arena_prestige,
    ranks: arena_prestige_ranks,
    rewards: arena_prestige_rewards

  {:ok, quest_prices_attrs} =
    Application.app_dir(:game_backend, "priv/curse_of_mirra/quest_reroll_configuration.json")
    |> File.read()

  config :game_backend, :quest_reroll_config, Jason.decode!(quest_prices_attrs, [{:keys, :atoms}])
end

##################################
# App configuration: game_client #
##################################

config :game_client, :gateway_url, System.get_env("GATEWAY_URL") || "http://localhost:4001"

if System.get_env("PHX_SERVER") do
  config :game_client, GameClientWeb.Endpoint, server: true
end

if config_env() == :prod do
  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("GAME_CLIENT_HOST") || "gameclient-example.com"
  port = String.to_integer(System.get_env("GAME_CLIENT_PORT") || "3000")

  config :game_client, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :game_client, GameClientWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  # Newrelic agent
  newrelic_license_key =
    System.get_env("NEWRELIC_KEY")

  newrelic_app_name =
    System.get_env("NEWRELIC_APP_NAME")

  config :new_relic_agent,
    app_name: newrelic_app_name,
    license_key: newrelic_license_key,
    logs_in_context: :direct

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :game_client, GameClientWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your endpoint, ensuring
  # no data is ever sent via http, always redirecting to https:
  #
  #     config :game_client, GameClientWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :game_client, GameClient.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney and Finch out of the box:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.
end

##############################
# App configuration: gateway #
##############################

###################################
# App configuration: configurator #
###################################

if System.get_env("PHX_SERVER") do
  config :configurator, ConfiguratorWeb.Endpoint, server: true
end

if config_env() == :prod do
  database_url =
    System.get_env("CONFIGURATOR_DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :configurator, Configurator.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("CONFIGURATOR_HOST") || "example.com"
  port = String.to_integer(System.get_env("CONFIGURATOR_PORT") || "4100")

  config :configurator, ConfiguratorWeb.Endpoint,
    url: [host: host, port: port],
    http: [ip: {127, 0, 0, 1}, port: port],
    secret_key_base: secret_key_base

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :configurator, ConfiguratorWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :configurator, ConfiguratorWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.
end

###################################
# App configuration: Bot Manager  #
###################################

bot_manager_port =
  if System.get_env("BOT_MANAGER_PORT") in [nil, ""] do
    4003
  else
    System.get_env("BOT_MANAGER_PORT") |> String.to_integer()
  end

config :bot_manager, :end_point_configuration,
  scheme: :http,
  plug: BotManager.Endpoint,
  options: [port: bot_manager_port]

###################################
