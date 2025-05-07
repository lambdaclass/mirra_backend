defmodule Arena.Bots.BotSupervisor do
  @moduledoc """
  Dynamic Supervisor for bots' GenServers.
  """
  use DynamicSupervisor
  alias Arena.Bots.Bot

  def start_link(_args) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Instances bot GenServers for a game.
  """
  def start_bots_for_game(bot_clients, game_id) do
    game_topic = get_game_topic(game_id)

    Enum.reduce(bot_clients, [], fn %{client_id: bot_id}, pids ->
      {:ok, pid} =
        DynamicSupervisor.start_child(__MODULE__, {Bot, %{bot_id: bot_id, game_id: game_id, game_topic: game_topic}})

      pids ++ [pid]
    end)
  end

  @doc """
  Returns PubSub game topic.
  """
  def get_game_topic(game_id), do: "BOTS_#{game_id}"

  @doc """
  Terminates all the bots GenServers.
  """
  def terminate_bots() do
    bots = DynamicSupervisor.which_children(__MODULE__)

    Enum.each(bots, fn {_, bot_pid, _, _} ->
      DynamicSupervisor.terminate_child(__MODULE__, bot_pid)
    end)
  end
end
