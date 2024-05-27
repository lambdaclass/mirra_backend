defmodule Arena.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ArenaWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:arena, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Arena.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Arena.Finch},
      # Start game launcher genserver
      Arena.GameLauncher,
      Arena.BountyUpdater,
      Arena.GameTracker,
      # Start a worker by calling: Arena.Worker.start_link(arg)
      # {Arena.Worker, arg},
      # Start to serve requests, typically the last entry
      ArenaWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Arena.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ArenaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
