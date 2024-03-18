defmodule BotManager.BotSupervisor do
  @moduledoc """
  This will be the endrypoint to spawn bots and assign them to games
  """
  use DynamicSupervisor

  def start_link(init_args) do
    DynamicSupervisor.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def spawn_bot(bot_config) do
    IO.inspect(bot_config, label: "aber bot config")
    DynamicSupervisor.start_child(__MODULE__, {BotManager.SocketHandler, bot_config})
  end

  def add_bot_to_game(client_id, game_id) do
    DynamicSupervisor.start_child(__MODULE__, {BotManager.GameSocketHandler, {client_id, game_id}})
  end
end
