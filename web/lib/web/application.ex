defmodule Web.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      WebWeb.Telemetry,
      # GameBackend.Repo,
      # {DNSCluster, query: Application.get_env(:game_backend, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: GameBackend.PubSub},
      # Start the Finch HTTP client for sending emails
      # {Finch, name: GameBackend.Finch},
      # Start game launcher genserver
      # GameBackend.GameLauncher,
      # Start a worker by calling: GameBackend.Worker.start_link(arg)
      # {GameBackend.Worker, arg},
      # Start to serve requests, typically the last entry
      WebWeb.Endpoint
    ]

    Application.ensure_all_started(:game_backend) |> IO.inspect(label: :aver_ensure_all_started)

    IO.inspect("FALOPA")
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Web.Supervisor]
    Supervisor.start_link(children, opts)
    |> IO.inspect(label: :aver)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    WebWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
