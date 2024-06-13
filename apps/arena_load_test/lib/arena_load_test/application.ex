defmodule ArenaLoadTest.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ArenaLoadTest.SocketSupervisor,
      ArenaLoadTest.LoadtestManager,
      {Finch, name: ArenaLoadTest.Finch},
      ArenaLoadTest.TokenFetcher
      # Starts a worker by calling: ArenaLoadTest.Worker.start_link(arg)
      # {ArenaLoadTest.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ArenaLoadTest.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
