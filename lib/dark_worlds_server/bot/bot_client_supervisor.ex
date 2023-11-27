defmodule DarkWorldsServer.Bot.BotClientSupervisor do
  use DynamicSupervisor
  alias DarkWorldsServer.Bot.BotClient

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def start_bot_clients(game_id, bot_count, config) do
    Enum.each(1..bot_count//1, fn _ ->
      {:ok, _child_pid} = DynamicSupervisor.start_child(__MODULE__, {BotClient, %{game_id: game_id, config: config}})
    end)
    :ok
  end

  @impl true
  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
