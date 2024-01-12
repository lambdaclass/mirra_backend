defmodule Arena.GameUpdater do
  @moduledoc """
  GenServer that broadcasts the latest game update to every client
  (player websocket).
  """
  alias Arena.Protobuf.GameState
  use GenServer
  alias Phoenix.PubSub

  # Time between game updates in ms
  @game_tick 30

  # API
  def join(game_pid, player_id) do
    GenServer.call(game_pid, {:join, player_id})
  end

  def move(game_pid, player_id, direction) do
    GenServer.call(game_pid, {:move, player_id, direction})
  end

  def attack(game_pid, player_id, skill) do
    GenServer.call(game_pid, {:attack, player_id, skill})
  end

  # Callbacks
  def init(%{players: players}) do
    game_id = self() |> :erlang.term_to_binary() |> Base58.encode()

    state =
      Enum.reduce(players, Physics.new_game(game_id), fn {player_id, _client_id}, state ->
        Physics.add_player(state, String.to_integer(player_id))
      end)
      |> Physics.add_polygon()

    Process.send_after(self(), :update_game, @game_tick)
    {:ok, state}
  end

  def handle_info(:update_game, state) do
    Process.send_after(self(), :update_game, @game_tick)

    state = Physics.move_entities(state)

    entities =
      Enum.reduce(state.entities, %{}, fn {entity_id, entity}, entities ->
        entity =
          Map.put(entity, :is_colliding, Physics.check_collisions(entity, state.entities))
          |> Map.put(:category, to_string(entity.category))
          |> Map.put(:shape, to_string(entity.shape))
          |> Map.put(:name, "Entity" <> Integer.to_string(entity_id))

        Map.put(entities, entity_id, entity)
      end)

    encoded_state =
      GameState.encode(%GameState{
        game_id: state.game_id,
        entities: entities
      })

    PubSub.broadcast(Arena.PubSub, state.game_id, {:game_update, encoded_state})

    {:noreply, state}
  end

  def handle_call({:join, player_id}, _from, state) do
    {:reply, :ok, Physics.add_player(state, String.to_integer(player_id))}
  end

  def handle_call({:move, player_id, _direction = {x, y}}, _from, state) do
    state = Physics.move_player(state, player_id |> String.to_integer(), x, y)

    {:reply, :ok, state}
  end

  def handle_call({:attack, player_id, _skill}, _from, state) do
    current_player = Map.get(state.entities, String.to_integer(player_id))

    state =
      Physics.add_projectile(state, current_player.position, 10.0, 10.0, current_player.direction)

    {:reply, :ok, state}
  end
end
