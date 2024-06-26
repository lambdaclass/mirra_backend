defmodule ArenaLoadTest.SocketSupervisor do
  @moduledoc """
  Dynamic Supervisor for the websockets connections.
  """
  use DynamicSupervisor
  alias ArenaLoadTest.SocketHandler
  alias ArenaLoadTest.GameSocketHandler
  alias ArenaLoadTest.LoadtestManager
  require Logger

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__, max_restarts: 1)
  end

  @impl true
  def init(_opts) do
    create_ets_table(:clients)
    create_ets_table(:players)
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Initializes a websocket that handles the client connection in the game waiting queue.
  """
  def add_new_client(client_id) do
    true = :ets.insert(:clients, {client_id, client_id})

    DynamicSupervisor.start_child(
      __MODULE__,
      {SocketHandler, client_id}
    )
  end

  @doc """
  Initializes a websocket that handles the client connection in-game.
  """
  def add_new_player(client_id, game_id) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {GameSocketHandler, {client_id, game_id}}
    )
  end

  @doc """
  Loadtests entrypoint.
  Creates given amount of clients that will join and play a game for the given duration.
  """
  def spawn_players(num_clients, playtime_duration_ms \\ 99_999_999) do
    send(LoadtestManager, :clients_log)
    Process.send_after(LoadtestManager, :loadtest_finished, playtime_duration_ms)

    Enum.each(1..num_clients, fn client_number ->
      Logger.info("Iteration: #{client_number}")
      {:ok, _pid} = ArenaLoadTest.SocketSupervisor.add_new_client(client_number)
    end)
  end

  @doc """
  Terminates all the websocket connections.
  """
  def terminate_children() do
    children = DynamicSupervisor.which_children(__MODULE__)

    Enum.each(children, fn {_, child_pid, _, _} ->
      DynamicSupervisor.terminate_child(__MODULE__, child_pid)
    end)
  end

  # Create a public ets table by given name.
  # Table is not created if it exists already.
  defp create_ets_table(table_name) do
    case :ets.whereis(table_name) do
      :undefined -> :ets.new(table_name, [:set, :named_table, :public])
      _table_exists_already -> nil
    end
  end
end
