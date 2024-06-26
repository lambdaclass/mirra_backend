defmodule Champions.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  alias Champions.Config

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Champions.Worker.start_link(arg)
      # {Champions.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options

    Config.import_proximity_config()
    Config.import_fusion_config()

    opts = [strategy: :one_for_one, name: Champions.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
