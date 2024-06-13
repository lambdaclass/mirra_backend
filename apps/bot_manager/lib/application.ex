defmodule BotManager.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      BotManager.BotSupervisor,
      {Plug.Cowboy, Application.get_env(:bot_manager, :end_point_configuration)},
      {Finch, name: BotManager.Finch},
      BotManager.TokenFetcher
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BotManager.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
