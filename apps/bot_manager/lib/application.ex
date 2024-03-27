defmodule BotManager.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    http_server =
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: BotManager.Endpoint,
        options: Application.get_env(:bot_manager, :end_point)[:port]
      )

    children = [
      BotManager.BotSupervisor,
      http_server
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BotManager.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
