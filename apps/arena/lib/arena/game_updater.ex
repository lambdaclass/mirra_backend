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

  ##################
  # API
  ##################
  def join(game_pid, player_id) do
    GenServer.call(game_pid, {:join, player_id})
  end

  def move(game_pid, player_id, direction, timestamp) do
    GenServer.call(game_pid, {:move, player_id, direction, timestamp})
  end

  def attack(game_pid, player_id, skill) do
    GenServer.call(game_pid, {:attack, player_id, skill})
  end

  ##################
  # Callbacks
  ##################
  def init(%{players: players}) do
    game_id = self() |> :erlang.term_to_binary() |> Base58.encode()
    state = new_game(game_id, players)

    Process.send_after(self(), :update_game, 1_000)
    {:ok, state}
  end

  def handle_info(:update_game, state) do
    Process.send_after(self(), :update_game, @game_tick)

    entities_to_collide = Map.merge(state.players, state.projectiles)
    new_players_state = update_entities(state.players, entities_to_collide)
    new_projectiles_state = update_entities(state.projectiles, entities_to_collide)

    state =
      state
      |> Map.put(:players, new_players_state)
      |> Map.put(:projectiles, new_projectiles_state)

    broadcast_game_update(state)

    {:noreply, state}
  end

  def handle_call({:move, player_id, _direction = {x, y}, timestamp}, _from, state) do
    player =
      state.players
      |> Map.get(String.to_integer(player_id))
      |> Map.put(:direction, %{x: x, y: y})

    players = state.players |> Map.put(String.to_integer(player_id), player)

    state =
      state
      |> Map.put(:players, players)
      |> Map.put(:player_timestamp, timestamp)

    {:reply, :ok, state}
  end

  def handle_call({:attack, player_id, _skill}, _from, state) do
    current_player = Map.get(state.players, String.to_integer(player_id))

    last_id = state.last_id + 1

    projectiles =
      state.projectiles
      |> Map.put(
        last_id,
        Entities.new_projectile(
          last_id,
          current_player.position,
          current_player.direction,
          current_player.id
        )
      )

    state =
      state
      |> Map.put(:last_id, last_id)
      |> Map.put(:projectiles, projectiles)

    {:reply, :ok, state}
  end

  ##################
  # Private
  ##################

  # Game creation
  defp new_game(game_id, players) do
    new_game =
      Physics.new_game(game_id)
      |> Map.put(:last_id, 0)
      |> Map.put(:players, %{})
      |> Map.put(:projectiles, %{})
      |> Map.put(:player_timestamp, 0)
      |> Map.put(:server_timestamp, 0)

    Enum.reduce(players, new_game, fn {_player_id, _client_id}, new_game ->
      last_id = new_game.last_id + 1
      players = new_game.players |> Map.put(last_id, Entities.new_player(last_id))

      new_game
      |> Map.put(:last_id, last_id)
      |> Map.put(:players, players)
    end)
  end

  # Move entities and add game fields
  defp update_entities(entities, entities_to_collide) do
    new_state = Physics.move_entities(entities)

    Enum.reduce(new_state, %{}, fn {key, value}, acc ->
      entity =
        Map.get(entities, key)
        |> Map.merge(value)
        |> Map.put(
          :is_colliding,
          Physics.check_collisions(value, entities_to_collide) |> Enum.any?()
        )

      acc |> Map.put(key, entity)
    end)
  end

  # Broadcast game update to all players
  defp broadcast_game_update(state) do
    players = complete_entities(state.players)
    projectiles = complete_entities(state.projectiles)

    encoded_state =
      GameState.encode(%GameState{
        game_id: state.game_id,
        players: players,
        projectiles: projectiles,
        server_timestamp: DateTime.utc_now() |> DateTime.to_unix(:millisecond),
        player_timestamp: state.player_timestamp
      })

    PubSub.broadcast(Arena.PubSub, state.game_id, {:game_update, encoded_state})
  end

  defp complete_entities(entities) do
    entities
    |> Enum.reduce(%{}, fn {entity_id, entity}, entities ->
      entity =
        Map.put(entity, :category, to_string(entity.category))
        |> Map.put(:shape, to_string(entity.shape))
        |> Map.put(:name, "Entity" <> Integer.to_string(entity_id))
        |> Map.put(:aditional_info, entity |> Entities.maybe_add_custom_info())

      Map.put(entities, entity_id, entity)
    end)
  end
end
