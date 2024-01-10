defmodule GameBackend.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      GameBackend.Repo,
      {Phoenix.PubSub, name: GameBackend.PubSub},
      # Start game launcher genserver
      GameBackend.GameLauncher,
      # Start a worker by calling: GameBackend.Worker.start_link(arg)
      # {GameBackend.Worker, arg},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GameBackend.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
