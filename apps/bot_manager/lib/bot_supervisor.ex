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

  def add_bot_to_game(bot_config) do
    if System.get_env("BOTS_ACTIVE") == "true" do
      DynamicSupervisor.start_child(__MODULE__, {BotManager.GameSocketHandler, bot_config})
    end
  end
end
