defmodule LambdaGameBackend.GameLauncher do
  @moduledoc false

  use GenServer

  # Amount of players needed to start a game
  @players_needed 10

  # API
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def join(player_id) do
    GenServer.call(__MODULE__, {:join, player_id})
  end

  # Callbacks
  @impl true
  def init(_) do
    Process.send_after(self(), :launch_game?, 300)
    {:ok, %{players: []}}
  end

  @impl true
  def handle_call({:join, player_id}, {client_id, _}, %{players: players} = state) do
    {:reply, :ok, %{state | players: players ++ [{player_id, client_id}]}}
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

    {:ok, game_pid} = GenServer.start(LambdaGameBackend.GameUpdater, %{players: game_players})

    game_id = game_pid |> :erlang.term_to_binary() |> Base58.encode()

    Enum.each(game_players, fn {_player_id, client_id} ->
      Process.send(client_id, {:join_game, game_id}, [])
      Process.send(client_id, :leave_waiting_game, [])
    end)

    {:noreply, %{state | players: remaining_players}}
  end
end
