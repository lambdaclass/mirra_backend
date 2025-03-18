defmodule Arena.Bots.BotSupervisor do
  @moduledoc """
  Dynamic Supervisor for bots.
  """
  use DynamicSupervisor
  alias Arena.Bots.Bot
  require Logger

  def start_link(_args) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Initializes a new bot instance.
  """
  def start_bot(bot_id, game_id) do
    IO.inspect("starteando botardo")
    DynamicSupervisor.start_child(__MODULE__, {Bot, %{bot_id: bot_id, game_id: game_id}})
  end

  @doc """
  Terminates all the bots instances.
  """
  def terminate_bots() do
    bots = DynamicSupervisor.which_children(__MODULE__)

    Enum.each(bots, fn {_, bot_pid, _, _} ->
      DynamicSupervisor.terminate_child(__MODULE__, bot_pid)
    end)
  end
end
