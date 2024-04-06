defmodule BotManager.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    options = [port: get_bot_manager_port()]

    children = [
      BotManager.BotSupervisor,
      {Plug.Cowboy, scheme: :http, plug: BotManager.Endpoint, options: options}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BotManager.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp get_bot_manager_port() do
    case System.get_env("BOT_MANAGER_PORT") do
      nil -> 4003
      port -> String.to_integer(port)
    end
  end
end
