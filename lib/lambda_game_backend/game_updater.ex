defmodule LambdaGameBackend.GameUpdater do
  @moduledoc """
  GenServer that broadcasts the latest game update to every client
  (player websocket).
  """
  use GenServer
  alias Phoenix.PubSub

  # Time between game updates in ms
  @game_tick 30

  # API
  def move(game_pid, player_id, new_position) do
    GenServer.call(game_pid, {:move, player_id, new_position})
  end

  def join(game_pid, player_id) do
    GenServer.call(game_pid, {:join, player_id})
  end

  # Callbacks
  def init(%{players: players}) do
    game_id = self() |> :erlang.term_to_binary() |> Base58.encode()

    state =
      Enum.reduce(players, StateManagerBackend.new_game(game_id), fn {player_id, _client_id}, state ->
        StateManagerBackend.add_player(state, String.to_integer(player_id))
      end)

    Process.send_after(self(), :update_game, @game_tick)
    {:ok, state}
  end

  def handle_info(:update_game, state) do
    Process.send_after(self(), :update_game, @game_tick)

    encoded_players =
      Enum.reduce(state.players, %{}, fn {_player_id, player}, acc ->
        player_encoded =
          LambdaGameBackend.Protobuf.Player.encode(%LambdaGameBackend.Protobuf.Player{
            id: player.id,
            speed: player.speed,
            position: %LambdaGameBackend.Protobuf.Position{
              x: player.position.x,
              y: player.position.y
            }
          })

        Map.put(acc, player.id, player_encoded)
      end)

    PubSub.broadcast(LambdaGameBackend.PubSub, state.game_id, encoded_players)

    {:noreply, state}
  end

  def handle_call({:join, player_id}, _from, state) do
    {:reply, :ok, StateManagerBackend.add_player(state, String.to_integer(player_id))}
  end

  def handle_call({:move, player_id, _new_position = {x, y}}, _from, state) do
    state = StateManagerBackend.move_player(state, player_id |> String.to_integer(), x, y)

    {:reply, :ok, state}
  end
end
