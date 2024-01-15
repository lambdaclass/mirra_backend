defmodule Arena.GameLauncher do
  @moduledoc false

  use GenServer

  # Amount of players needed to start a game
  @players_needed 1

  # API
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def join(client_id) do
    GenServer.call(__MODULE__, {:join, client_id})
  end

  # Callbacks
  @impl true
  def init(_) do
    Process.send_after(self(), :launch_game?, 300)
    {:ok, %{players: []}}
  end

  @impl true
  def handle_call({:join, client_id}, {from_pid, _}, %{players: players} = state) do
    {:reply, :ok, %{state | players: players ++ [{client_id, from_pid}]}}
  end

  @impl true
  def handle_info(:launch_game?, %{players: players} = state) do
    Process.send_after(self(), :launch_game?, 300)

    if length(players) >= @players_needed do
      Process.send(self(), :start_game, [])
    end

    {:noreply, state}
  end

  def handle_info(:start_game, state) do
    {game_players, remaining_players} = Enum.split(state.players, @players_needed)

    {:ok, game_pid} = GenServer.start(Arena.GameUpdater, %{players: game_players})

    game_id = game_pid |> :erlang.term_to_binary() |> Base58.encode()

    Enum.each(game_players, fn {_player_id, from_pid} ->
      Process.send(from_pid, {:join_game, game_id}, [])
      Process.send(from_pid, :leave_waiting_game, [])
    end)

    {:noreply, %{state | players: remaining_players}}
  end
end
