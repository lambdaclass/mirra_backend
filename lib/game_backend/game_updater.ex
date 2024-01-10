defmodule GameBackend.GameUpdater do
  @moduledoc """
  GenServer that broadcasts the latest game update to every client
  (player websocket).
  """
  use GenServer
  alias Phoenix.PubSub

  alias GameBackend.Entities

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

    state = Physics.new_game(game_id) |> Map.put(:last_id, 0)

    state =
      Enum.reduce(players, state, fn {_player_id, _client_id}, state ->
        last_id = state.last_id + 1
        entities = state.entities |> Map.put(last_id, Entities.new_player(last_id))

        state
        |> Map.put(:last_id, last_id)
        |> Map.put(:entities, entities)
      end)

    Process.send_after(self(), :update_game, 5_000)
    {:ok, state}
  end

  def handle_info(:update_game, state) do
    Process.send_after(self(), :update_game, @game_tick)

    state = Physics.move_entities(state)

    encoded_entities =
      Enum.map(state.entities, fn {_entity_id, entity} ->
        entity = entity |> Map.put(:is_colliding, Physics.check_collisions(entity, state.entities))
        Entities.encode(entity)
      end)

    PubSub.broadcast(GameBackend.PubSub, state.game_id, encoded_entities)

    {:noreply, state}
  end

  def handle_call({:move, player_id, _direction = {x, y}}, _from, state) do
    state = Physics.move_player(state, player_id |> String.to_integer(), x, y)

    {:reply, :ok, state}
  end

  def handle_call({:attack, player_id, _skill}, _from, state) do
    current_player = Map.get(state.entities, String.to_integer(player_id))

    last_id = state.last_id + 1

    entities =
      state.entities
      |> Map.put(last_id, Entities.new_projectile(last_id, current_player.position, current_player.direction))

    state =
      state
      |> Map.put(:last_id, last_id)
      |> Map.put(:entities, entities)

    {:reply, :ok, state}
  end
end
