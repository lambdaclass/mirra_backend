defmodule LambdaGameBackend.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LambdaGameBackendWeb.Telemetry,
      LambdaGameBackend.Repo,
      {DNSCluster, query: Application.get_env(:lambda_game_backend, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: LambdaGameBackend.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: LambdaGameBackend.Finch},
      # Start a worker by calling: LambdaGameBackend.Worker.start_link(arg)
      # {LambdaGameBackend.Worker, arg},
      # Start to serve requests, typically the last entry
      LambdaGameBackendWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LambdaGameBackend.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LambdaGameBackendWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
