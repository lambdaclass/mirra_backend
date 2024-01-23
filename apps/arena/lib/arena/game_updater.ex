defmodule Arena.GameUpdater do
  @moduledoc """
  GenServer that broadcasts the latest game update to every client
  (player websocket).
  """

  use GenServer
  alias Arena.Configuration
  alias Arena.Entities
  alias Arena.Serialization.{GameEvent, GameState, GameFinished}
  alias Arena.Utils
  alias Phoenix.PubSub

  ## Time between checking that a game has ended
  @check_game_ended_interval_ms 1_000
  ## Time to wait between a game ended detected and shutting down this process
  @game_ended_shutdown_wait_ms 10_000

  ##########################
  # API
  ##########################
  def join(game_pid, client_id) do
    GenServer.call(game_pid, {:join, client_id})
  end

  def move(game_pid, player_id, direction, timestamp) do
    GenServer.call(game_pid, {:move, player_id, direction, timestamp})
  end

  def attack(game_pid, player_id, skill) do
    GenServer.call(game_pid, {:attack, player_id, skill})
  end

  ##########################
  # END API
  ##########################

  ##########################
  # Callbacks
  ##########################
  def init(%{clients: clients}) do
    game_id = self() |> :erlang.term_to_binary() |> Base58.encode()
    game_config = Configuration.get_game_config()
    game_state = new_game(game_id, clients, game_config)

    Process.send_after(self(), :update_game, 1_000)
    Process.send_after(self(), :check_game_ended, @check_game_ended_interval_ms * 10)

    {:ok, %{game_config: game_config, game_state: game_state}}
  end

  def handle_info(:update_game, %{game_state: game_state} = state) do
    Process.send_after(self(), :update_game, state.game_config.game.tick_rate_ms)

    entities_to_collide = Map.merge(game_state.players, game_state.projectiles)

    new_players_state =
      update_entities(game_state.players, entities_to_collide, game_state.external_wall)

    new_projectiles_state =
      update_entities(game_state.projectiles, entities_to_collide, game_state.external_wall)

    game_state =
      game_state
      |> Map.put(:players, new_players_state)
      |> Map.put(:projectiles, new_projectiles_state)

    broadcast_game_update(game_state)

    {:noreply, %{state | game_state: game_state}}
  end

  def handle_info({:remove_skill_action, player_id, skill_action}, state) do
    player = Map.get(state.game_state.players, player_id)
    actions =
      player.aditional_info.current_actions
      |> Enum.reject(fn action -> action.action == skill_action end)

    state = put_in(state, [:game_state, :players, player_id, :aditional_info, :current_actions], actions)
    {:noreply, state}
  end

  # End game
  def handle_info(:game_ended, state) do
    {:stop, :normal, state}
  end

  def handle_info(:check_game_ended, state) do
    Process.send_after(self(), :check_game_ended, @check_game_ended_interval_ms)

    case check_game_ended(Map.values(state.game_state.players), state.game_state.players) do
      :ongoing ->
        :skip

      {:ended, winner} ->
        broadcast_game_ended(winner, state.game_state)

        ## The idea of having this waiting period is in case websocket processes keep
        ## sending messages, this way we give some time before making them crash
        ## (sending to inexistant process will cause them to crash)
        Process.send_after(self(), :game_ended, @game_ended_shutdown_wait_ms)
    end

    {:noreply, state}
  end

  def handle_call({:move, player_id, direction = {x, y}, timestamp}, _from, state) do
    player =
      state.game_state.players
      |> Map.get(player_id)

    current_actions = add_or_remove_moving_action(player.aditional_info.current_actions, direction)

    player = player
    |> Map.put(:direction, Utils.normalize(x, y))
    |> Map.put(:aditional_info, Map.merge(player.aditional_info, %{current_actions: current_actions}))

    players = state.game_state.players |> Map.put(player_id, player)

    game_state =
      state.game_state
      |> Map.put(:players, players)
      |> Map.put(:player_timestamp, timestamp)

    {:reply, :ok, %{state | game_state: game_state}}
  end

  def handle_call({:attack, player_id, skill}, _from, %{game_state: game_state} = state) do
    game_state = handle_attack(player_id, skill, game_state)
    {:reply, :ok, %{state | game_state: game_state}}
  end

  def handle_call({:join, client_id}, _from, state) do
    player_id = get_in(state.game_state, [:client_to_player_map, client_id])
    response = %{player_id: player_id, game_config: state.game_config}
    {:reply, {:ok, response}, state}
  end

  ##########################
  # End callbacks
  ##########################

  ##########################
  # Broadcast
  ##########################

  # Broadcast game update to all players
  defp broadcast_game_update(state) do
    game_state = %GameState{
      game_id: state.game_id,
      players: complete_entities(state.players),
      projectiles: complete_entities(state.projectiles),
      server_timestamp: DateTime.utc_now() |> DateTime.to_unix(:millisecond),
      player_timestamp: state.player_timestamp
    }

    encoded_state =
      GameEvent.encode(%GameEvent{
        event: {:update, game_state}
      })

    PubSub.broadcast(Arena.PubSub, state.game_id, {:game_update, encoded_state})
  end

  defp broadcast_game_ended(winner, state) do
    game_state = %GameFinished{
      winner: complete_entity(winner),
      players: complete_entities(state.players),
    }

    encoded_state =
      GameEvent.encode(%GameEvent{
        event: {:finished, game_state}
      })

    PubSub.broadcast(Arena.PubSub, state.game_id, {:game_finished, encoded_state})
  end

  defp complete_entities(entities) do
    entities
    |> Enum.reduce(%{}, fn {entity_id, entity}, entities ->
      entity = complete_entity(entity)

      Map.put(entities, entity_id, entity)
    end)
  end

  defp complete_entity(entity) do
    Map.put(entity, :category, to_string(entity.category))
      |> Map.put(:shape, to_string(entity.shape))
      |> Map.put(:name, "Entity" <> Integer.to_string(entity.id))
      |> Map.put(:aditional_info, entity |> Entities.maybe_add_custom_info())
  end

  ##########################
  # End broadcast
  ##########################

  ##########################
  # Skills mechaninc
  ##########################

  defp handle_attack(player_id, skill_key, game_state) do
    case Map.get(game_state.players, player_id) do
      %{aditional_info: %{skills: %{^skill_key => skill}}} = player ->

        player = add_skill_action(player, skill, skill_key)
        players = Map.put(game_state.players, player_id, player)
        game_state = %{game_state | players: players}

        Enum.reduce(skill.mechanics, game_state, fn (mechanic, game_state_acc) ->
          do_mechanic(mechanic, player, game_state_acc)
        end)

      _ ->
        game_state
    end
  end

  defp do_mechanic({:hit, hit}, player, game_state) do
    circular_damage_area = %{
      id: player.id,
      category: :obstacle,
      shape: :circle,
      name: "BashDamageArea",
      position: player.position,
      radius: hit.range,
      vertices: [],
      speed: 0.0,
      direction: %{
        x: 0.0,
        y: 0.0
      }
    }

    players =
      Physics.check_collisions(circular_damage_area, game_state.players)
      |> Enum.reduce(game_state.players, fn (player_id, players_acc) ->
        player =
          Map.get(players_acc, player_id)
          |> update_in([:aditional_info, :health], fn health -> max(health - hit.damage, 0) end)

        Map.put(players_acc, player_id, player)
      end)

    %{game_state | players: players}
  end

  defp do_mechanic({:simple_shoot, _}, player, game_state) do
    last_id = game_state.last_id + 1

    projectiles =
      game_state.projectiles
      |> Map.put(
        last_id,
        Entities.new_projectile(
          last_id,
          player.position,
          player.direction,
          player.id
        )
      )

    game_state
    |> Map.put(:last_id, last_id)
    |> Map.put(:projectiles, projectiles)
  end

  defp add_or_remove_moving_action(current_actions, direction) do
    if direction == %{x: 0.0, y: 0.0} do
      current_actions -- [%{action: :MOVING, duration: 0}]
    else
      current_actions ++ [%{action: :MOVING, duration: 0}]
    end
    |> Enum.uniq()
  end

  defp add_skill_action(player, skill, skill_key) do

    Process.send_after(self(), {:remove_skill_action, player.id, skill_key_to_atom(skill_key)}, skill.execution_duration_ms)

    player
    |> update_in([:aditional_info, :current_actions], fn current_actions ->
      current_actions ++ [%{action: skill_key_to_atom(skill_key), duration: skill.execution_duration_ms}]
    end)
  end

  defp skill_key_to_atom(skill_key) do
    "EXECUTING_SKILL_#{String.upcase(skill_key)}" |> String.to_existing_atom()
  end

  ##########################
  # End skills mechaninc
  ##########################

  ##########################
  # Game flow
  ##########################

  # Create a new game
  defp new_game(game_id, clients, config) do
    new_game =
      Map.new(game_id: game_id)
      |> Map.put(:last_id, 0)
      |> Map.put(:players, %{})
      |> Map.put(:projectiles, %{})
      |> Map.put(:player_timestamp, 0)
      |> Map.put(:server_timestamp, 0)
      |> Map.put(:client_to_player_map, %{})
      |> Map.put(:external_wall, Entities.new_external_wall(config.map.radius))

    Enum.reduce(clients, new_game, fn {client_id, _from_pid}, new_game ->
      last_id = new_game.last_id + 1
      players = new_game.players |> Map.put(last_id, Entities.new_player(last_id, config.skills))

      new_game
      |> Map.put(:last_id, last_id)
      |> Map.put(:players, players)
      |> put_in([:client_to_player_map, client_id], last_id)
    end)
  end

  # Move entities and add game fields
  defp update_entities(entities, entities_to_collide, external_wall) do
    new_state = Physics.move_entities(entities, external_wall)

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

  # Check if game has ended
  defp check_game_ended(players, last_standing_players) do
    players_alive = Enum.filter(players, fn player ->
      player.aditional_info.health > 0
    end)

    case players_alive do
      ^players ->
        :ongoing

      [_, _ | _] ->
        :ongoing

      [player] ->
        {:ended, player}

      [] ->
        # TODO we should use a tiebreaker instead of picking the 1st one in the list
        {:ended, hd(last_standing_players)}
    end
  end

  ##########################
  # End game flow
  ##########################
end
