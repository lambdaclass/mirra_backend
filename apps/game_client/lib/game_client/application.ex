defmodule GameClient.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      GameClientWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:game_client, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: GameClient.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: GameClient.Finch},
      # Start a worker by calling: GameClient.Worker.start_link(arg)
      # {GameClient.Worker, arg},
      # Start to serve requests, typically the last entry
      GameClientWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GameClient.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    GameClientWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
