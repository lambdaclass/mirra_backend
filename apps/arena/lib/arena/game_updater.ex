defmodule Arena.GameUpdater do
  @moduledoc """
  GenServer that broadcasts the latest game update to every client
  (player websocket).
  """
  alias Arena.Protobuf.GameState
  use GenServer
  alias Phoenix.PubSub

  alias Arena.Entities

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

    Process.send_after(self(), :update_game, 1_000)
    {:ok, state}
  end

  def handle_info(:update_game, state) do
    Process.send_after(self(), :update_game, @game_tick)

    new_state = Physics.move_entities(state)

    state =
      Enum.reduce(new_state.entities, state, fn {new_entity_id, new_entity}, state ->
        entity =
          Map.get(state.entities, new_entity_id)
          |> Map.merge(new_entity)
          |> Map.put(:is_colliding, Physics.check_collisions(new_entity, state.entities))

        entities = state.entities |> Map.put(new_entity_id, entity)
        state |> Map.put(:entities, entities)
      end)

    entities =
      Enum.reduce(state.entities, %{}, fn {entity_id, entity}, entities ->
        IO.inspect(entity.aditional_info)
        entity =
          Map.put(entity, :is_colliding, Physics.check_collisions(entity, state.entities))
          |> Map.put(:category, to_string(entity.category))
          |> Map.put(:shape, to_string(entity.shape))
          |> Map.put(:name, "Entity" <> Integer.to_string(entity_id))
          |> Map.put(:aditional_info, entity |> Entities.maybe_add_custom_info())

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

  def handle_call({:move, player_id, _direction = {x, y}}, _from, state) do
    new_state = Physics.set_entity_direction(state, player_id |> String.to_integer(), x, y)

    state =
      Enum.reduce(new_state.entities, state, fn {new_entity_id, new_entity}, state ->
        entity =
          Map.get(state.entities, new_entity_id)
          |> Map.merge(new_entity)

        entities = state.entities |> Map.put(new_entity_id, entity)

        state
        |> Map.put(:entities, entities)
      end)

    {:reply, :ok, state}
  end

  def handle_call({:attack, player_id, _skill}, _from, state) do
    current_player = Map.get(state.entities, String.to_integer(player_id))

    last_id = state.last_id + 1

    entities =
      state.entities
      |> Map.put(
        last_id,
        Entities.new_projectile(last_id, current_player.position, current_player.direction, current_player.id)
      )

    state =
      state
      |> Map.put(:last_id, last_id)
      |> Map.put(:entities, entities)

    {:reply, :ok, state}
  end
end
