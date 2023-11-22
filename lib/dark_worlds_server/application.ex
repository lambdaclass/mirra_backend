defmodule DarkWorldsServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      DarkWorldsServerWeb.Telemetry,
      # Start the Ecto repository
      DarkWorldsServer.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: DarkWorldsServer.PubSub},
      # Start Finch
      {Finch, name: DarkWorldsServer.Finch},
      # Start the Endpoint (http/https)
      DarkWorldsServerWeb.Endpoint,
      # Start the Runner Supervisor
      DarkWorldsServer.RunnerSupervisor,
      # Start the matchmaking supervisor
      DarkWorldsServer.Matchmaking.MatchingCoordinator
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DarkWorldsServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DarkWorldsServerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
