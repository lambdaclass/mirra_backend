defmodule BotManager.BotSupervisor do
  use Supervisor

  def start_link(init_args) do
    Supervisor.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  def init(_init_arg) do
    children = []
    Supervisor.init(children, strategy: :one_for_one)
  end

  def spawn_bot(bot_config) do
    BotManager.Bot.start_link(bot_config)
  end
end
