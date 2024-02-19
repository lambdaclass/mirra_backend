defmodule Arena.GameUpdater do
  @moduledoc """
  GenServer that broadcasts the latest game update to every client
  (player websocket).
  """

  use GenServer
  alias Arena.Configuration
  alias Arena.Entities
  alias Arena.Game.Player
  alias Arena.Game.Skill
  alias Arena.Serialization.{GameEvent, GameState, GameFinished}
  alias Arena.Utils
  alias Phoenix.PubSub

  ## Time between checking that a game has ended
  @check_game_ended_interval_ms 1_000
  ## Time to wait between a game ended detected and shutting down this process
  @game_ended_shutdown_wait_ms 10_000
  ## Time between natural healing intervals
  @natural_healing_interval_ms 300

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

    Process.send_after(
      self(),
      {:check_game_ended, Map.keys(game_state.players)},
      @check_game_ended_interval_ms * 10
    )

    Process.send_after(self(), :natural_healing, @natural_healing_interval_ms * 10)
    Process.send_after(self(), :start_zone_shrink, game_config.game.zone_shrink_start_ms)

    {:ok, %{game_config: game_config, game_state: game_state}}
  end

  def handle_info(:update_game, %{game_state: game_state} = state) do
    Process.send_after(self(), :update_game, state.game_config.game.tick_rate_ms)

    now = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
    ticks_to_move = (now - game_state.server_timestamp) / state.game_config.game.tick_rate_ms

    entities_to_collide_projectiles =
      Map.merge(Player.alive_players(game_state.players), game_state.obstacles)

    players =
      game_state.players
      |> Physics.move_entities(ticks_to_move, state.game_state.external_wall)
      |> update_collisions(game_state.players, %{})

    projectiles =
      remove_exploded_projectiles(game_state.projectiles)
      |> Physics.move_entities(ticks_to_move, game_state.external_wall)
      |> update_collisions(
        game_state.projectiles,
        Map.merge(entities_to_collide_projectiles, %{
          game_state.external_wall.id => game_state.external_wall
        })
      )

    # Resolve collisions between players and projectiles
    {projectiles, players} =
      resolve_projectile_collisions(
        projectiles,
        players,
        game_state.obstacles,
        game_state.external_wall.id
      )

    players = apply_zone_damage(players, game_state.zone, state.game_config.game)

    game_state =
      game_state
      |> Map.put(:players, players)
      |> Map.put(:projectiles, projectiles)
      |> Map.put(:server_timestamp, now)

    broadcast_game_update(game_state)
    game_state = %{game_state | killfeed: [], damage_taken: %{}, damage_done: %{}}

    {:noreply, %{state | game_state: game_state}}
  end

  def handle_info({:remove_skill_action, player_id, skill_action}, state) do
    player =
      Map.get(state.game_state.players, player_id)
      |> Player.remove_action(skill_action)

    state = put_in(state, [:game_state, :players, player_id], player)
    {:noreply, state}
  end

  def handle_info({:stop_dash, player_id, previous_speed}, state) do
    player =
      Map.get(state.game_state.players, player_id)
      |> Player.reset_after_dash(previous_speed)

    state = put_in(state, [:game_state, :players, player_id], player)
    {:noreply, state}
  end

  def handle_info({:trigger_mechanic, player_id, mechanic}, state) do
    player = Map.get(state.game_state.players, player_id)
    game_state = Skill.do_mechanic(state.game_state, player, mechanic)
    state = Map.put(state, :game_state, game_state)
    {:noreply, state}
  end

  def handle_info({:delayed_skill_mechanics, player_id, mechanics}, state) do
    player = Map.get(state.game_state.players, player_id)
    game_state = Skill.do_mechanic(state.game_state, player, mechanics)
    {:noreply, %{state | game_state: game_state}}
  end

  # End game
  def handle_info(:game_ended, state) do
    {:stop, :normal, state}
  end

  def handle_info({:check_game_ended, last_players_ids}, state) do
    case check_game_ended(state.game_state.players, last_players_ids) do
      {:ongoing, players_ids} ->
        Process.send_after(
          self(),
          {:check_game_ended, players_ids},
          @check_game_ended_interval_ms
        )

      {:ended, winner} ->
        broadcast_game_ended(winner, state.game_state)

        ## The idea of having this waiting period is in case websocket processes keep
        ## sending messages, this way we give some time before making them crash
        ## (sending to inexistant process will cause them to crash)
        Process.send_after(self(), :game_ended, @game_ended_shutdown_wait_ms)
    end

    {:noreply, state}
  end

  # Natural healing
  def handle_info(:natural_healing, state) do
    Process.send_after(self(), :natural_healing, @natural_healing_interval_ms)

    players = Player.trigger_natural_healings(state.game_state.players)
    state = put_in(state, [:game_state, :players], players)
    {:noreply, state}
  end

  def handle_info(:start_zone_shrink, state) do
    Process.send_after(self(), :stop_zone_shrink, state.game_config.game.zone_stop_interval_ms)
    send(self(), :zone_shrink)
    state = put_in(state, [:game_state, :zone, :shrinking], :enabled)
    {:noreply, state}
  end

  def handle_info(:stop_zone_shrink, state) do
    Process.send_after(self(), :start_zone_shrink, state.game_config.game.zone_start_interval_ms)
    state = put_in(state, [:game_state, :zone, :shrinking], :disabled)
    {:noreply, state}
  end

  def handle_info(:zone_shrink, %{game_state: %{zone: %{shrinking: :enabled}}} = state) do
    Process.send_after(self(), :zone_shrink, 100)
    radius = max(state.game_state.zone.radius - 10.0, 0.0)
    state = put_in(state, [:game_state, :zone, :radius], radius)
    {:noreply, state}
  end

  def handle_info(:zone_shrink, %{game_state: %{zone: %{shrinking: :disabled}}} = state) do
    {:noreply, state}
  end

  def handle_info({:to_killfeed, killer_id, victim_id}, state) do
    entry = %{killer_id: killer_id, victim_id: victim_id}
    state = update_in(state, [:game_state, :killfeed], fn killfeed -> [entry | killfeed] end)
    broadcast_player_dead(state.game_state.game_id, victim_id)

    {:noreply, state}
  end

  def handle_info({:recharge_stamina, player_id}, state) do
    player =
      Map.get(state.game_state.players, player_id)
      |> Player.recharge_stamina()

    state = put_in(state, [:game_state, :players, player_id], player)
    {:noreply, state}
  end

  def handle_info({:damage_done, player_id, damage}, state) do
    state =
      update_in(state, [:game_state, :damage_done, player_id], fn
        nil -> damage
        current -> current + damage
      end)

    {:noreply, state}
  end

  def handle_info({:damage_taken, player_id, damage}, state) do
    state =
      update_in(state, [:game_state, :damage_taken, player_id], fn
        nil -> damage
        current -> current + damage
      end)

    {:noreply, state}
  end

  def handle_info({:remove_projectile, projectile_id}, state) do
    case Map.get(state.game_state.projectiles, projectile_id) do
      %{aditional_info: %{status: :ACTIVE}} ->
        state =
          put_in(
            state,
            [:game_state, :projectiles, projectile_id, :aditional_info, :status],
            :EXPLODED
          )

        {:noreply, state}

      _ ->
        {:noreply, state}
    end
  end

  def handle_call({:move, player_id, direction = {x, y}, timestamp}, _from, state) do
    player =
      state.game_state.players
      |> Map.get(player_id)

    current_actions =
      add_or_remove_moving_action(player.aditional_info.current_actions, direction)

    is_moving = x != 0.0 || y != 0.0

    direction =
      case is_moving do
        true -> Utils.normalize(x, y)
        _ -> player.direction
      end

    player =
      player
      |> Map.put(:direction, direction)
      |> Map.put(:is_moving, is_moving)
      |> Map.put(
        :aditional_info,
        Map.merge(player.aditional_info, %{current_actions: current_actions})
      )

    players = state.game_state.players |> Map.put(player_id, player)

    game_state =
      state.game_state
      |> Map.put(:players, players)
      |> put_in([:player_timestamps, player_id], timestamp)

    {:reply, :ok, %{state | game_state: game_state}}
  end

  def handle_call({:attack, player_id, skill_key}, _from, state) do
    game_state =
      get_in(state, [:game_state, :players, player_id])
      |> Player.use_skill(skill_key, state.game_state)

    {:reply, :ok, %{state | game_state: game_state}}
  end

  def handle_call({:join, client_id}, _from, state) do
    case get_in(state.game_state, [:client_to_player_map, client_id]) do
      nil ->
        {:reply, :not_a_client, state}

      player_id ->
        response = %{player_id: player_id, game_config: state.game_config}
        {:reply, {:ok, response}, state}
    end
  end

  ##########################
  # End callbacks
  ##########################

  ##########################
  # Broadcast
  ##########################

  # Broadcast game update to all players
  defp broadcast_player_dead(game_id, player_id) do
    PubSub.broadcast(Arena.PubSub, game_id, {:player_dead, player_id})
  end

  defp broadcast_game_update(state) do
    encoded_state =
      GameEvent.encode(%GameEvent{
        event:
          {:update,
           %GameState{
             game_id: state.game_id,
             players: complete_entities(state.players),
             projectiles: complete_entities(state.projectiles),
             server_timestamp: state.server_timestamp,
             player_timestamps: state.player_timestamps,
             zone: state.zone,
             killfeed: state.killfeed,
             damage_taken: state.damage_taken,
             damage_done: state.damage_done
           }}
      })

    PubSub.broadcast(Arena.PubSub, state.game_id, {:game_update, encoded_state})
  end

  defp broadcast_game_ended(winner, state) do
    game_state = %GameFinished{
      winner: complete_entity(winner),
      players: complete_entities(state.players)
    }

    encoded_state = GameEvent.encode(%GameEvent{event: {:finished, game_state}})
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
  defp add_or_remove_moving_action(current_actions, direction) do
    if direction == {0.0, 0.0} do
      current_actions -- [%{action: :MOVING, duration: 0}]
    else
      current_actions ++ [%{action: :MOVING, duration: 0}]
    end
    |> Enum.uniq()
  end

  ##########################
  # End skills mechaninc
  ##########################

  ##########################
  # Game flow
  ##########################

  # Create a new game
  defp new_game(game_id, clients, config) do
    now = System.monotonic_time(:millisecond)

    new_game =
      Map.new(game_id: game_id)
      |> Map.put(:last_id, 0)
      |> Map.put(:players, %{})
      |> Map.put(:projectiles, %{})
      |> Map.put(:player_timestamps, %{})
      |> Map.put(:server_timestamp, 0)
      |> Map.put(:client_to_player_map, %{})
      |> Map.put(:external_wall, Entities.new_external_wall(0, config.map.radius))
      |> Map.put(:zone, %{radius: config.map.radius, shrinking: :disabled})

    {game, _} =
      Enum.reduce(clients, {new_game, config.map.initial_positions}, fn {client_id,
                                                                         character_name,
                                                                         _from_pid},
                                                                        {new_game, positions} ->
        last_id = new_game.last_id + 1
        {pos, positions} = get_next_position(positions)
        direction = Physics.get_direction_from_positions(pos, %{x: 0.0, y: 0.0})

        players =
          new_game.players
          |> Map.put(
            last_id,
            Entities.new_player(last_id, character_name, pos, direction, config, now)
          )

        new_game =
          new_game
          |> Map.put(:last_id, last_id)
          |> Map.put(:players, players)
          |> Map.put(:killfeed, [])
          |> Map.put(:damage_taken, %{})
          |> Map.put(:damage_done, %{})
          |> put_in([:client_to_player_map, client_id], last_id)
          |> put_in([:player_timestamps, last_id], 0)

        {new_game, positions}
      end)

    {obstacles, last_id} = initialize_obstacles(config.map.obstacles, game.last_id)

    game
    |> Map.put(:last_id, last_id)
    |> Map.put(:obstacles, obstacles)
  end

  # Initialize obstacles
  defp initialize_obstacles(obstacles, last_id) do
    Enum.reduce(obstacles, {Map.new(), last_id}, fn obstacle, {obstacles_acc, last_id} ->
      last_id = last_id + 1

      obstacles_acc =
        Map.put(obstacles_acc, last_id, Entities.make_polygon(last_id, obstacle.vertices))

      {obstacles_acc, last_id}
    end)
  end

  defp get_next_position([pos | rest]) do
    positions = rest ++ [pos]
    {pos, positions}
  end

  # Check entities collisiona
  defp update_collisions(new_entities, old_entities, entities_to_collide) do
    Enum.reduce(new_entities, %{}, fn {key, value}, acc ->
      entity =
        Map.get(old_entities, key)
        |> Map.merge(value)
        |> Map.put(
          :collides_with,
          Physics.check_collisions(value, entities_to_collide)
        )

      acc |> Map.put(key, entity)
    end)
  end

  # Check if game has ended
  defp check_game_ended(players, last_players_ids) do
    players_alive =
      Map.values(players)
      |> Enum.filter(&Player.alive?/1)

    case players_alive do
      [player] when map_size(players) > 1 ->
        {:ended, player}

      [] ->
        ## TODO: We probably should have a better tiebraker (e.g. most kills, less deaths, etc),
        ##    but for now a random between the ones that were alive last is enough
        player = Map.get(players, Enum.random(last_players_ids))
        {:ended, player}

      _ ->
        {:ongoing, Enum.map(players_alive, & &1.id)}
    end
  end

  def remove_exploded_projectiles(projectiles) do
    Map.filter(projectiles, fn {_key, projectile} ->
      projectile.aditional_info.status != :EXPLODED
    end)
  end

  ##########################
  # End game flow
  ##########################

  defp apply_zone_damage(players, zone, %{
         zone_damage_interval_ms: zone_interval,
         zone_damage: zone_damage
       }) do
    safe_zone = Entities.make_circular_area(0, %{x: 0.0, y: 0.0}, zone.radius)
    safe_ids = Physics.check_collisions(safe_zone, players)
    to_damage_ids = Map.keys(players) -- safe_ids
    now = System.monotonic_time(:millisecond)

    Enum.reduce(to_damage_ids, players, fn player_id, players_acc ->
      player = Map.get(players_acc, player_id)
      last_damage = player |> get_in([:aditional_info, :last_damage_received])
      elapse_time = now - last_damage

      player = player |> maybe_receive_zone_damage(elapse_time, zone_interval, zone_damage)

      Map.put(players_acc, player_id, player)
    end)
  end

  defp maybe_receive_zone_damage(player, elapse_time, zone_damage_interval, zone_damage)
       when elapse_time > zone_damage_interval do
    Player.take_damage(player, zone_damage)
  end

  defp maybe_receive_zone_damage(player, _elaptime, _zone_damage_interval, _zone_damage),
    do: player

  # This method will decide what to do when a projectile has collided with something in the map
  # - If collided with something with the same owner skip that collision
  # - If collided with external wall or obstacle explode projectile
  # - If collided with another player do the projectile's damage
  # - Do nothing on unexpected cases
  defp resolve_projectile_collisions(projectiles, players, obstacles, external_wall_id)

  defp resolve_projectile_collisions(projectiles, players, obstacles, external_wall_id) do
    Enum.reduce(projectiles, {projectiles, players}, fn {_projectile_id, projectile},
                                                        {_projectiles_acc, players_acc} = accs ->
      # check if the projectiles is inside the walls
      collides_with =
        case projectile.collides_with do
          [] -> [external_wall_id]
          entities -> List.delete(entities, external_wall_id)
        end

      collided_entity =
        decide_collided_entity(projectile, collides_with, external_wall_id, players_acc)

      apply_collision_updates(
        projectile,
        Map.get(players, collided_entity),
        Map.get(obstacles, collided_entity),
        collided_entity == external_wall_id,
        accs
      )
    end)
  end

  defp apply_collision_updates(projectile, player, obstacle, collided_with_external_wall?, accs)

  # Projectile collided an obstacle or went outside of the arena
  defp apply_collision_updates(
         projectile,
         nil,
         obstacle,
         collided_with_external_wall?,
         {projectiles_acc, players_acc}
       )
       when not is_nil(obstacle) or collided_with_external_wall? do
    projectile = put_in(projectile, [:aditional_info, :status], :EXPLODED)

    {
      Map.put(projectiles_acc, projectile.id, projectile),
      players_acc
    }
  end

  # Projectile collided a player
  defp apply_collision_updates(projectile, player, _, _, {projectiles_acc, players_acc})
       when not is_nil(player) do
    player = Player.take_damage(player, projectile.aditional_info.damage)

    send(
      self(),
      {:damage_done, projectile.aditional_info.owner_id, projectile.aditional_info.damage}
    )

    projectile = put_in(projectile, [:aditional_info, :status], :EXPLODED)

    unless Player.alive?(player) do
      send(self(), {:to_killfeed, projectile.aditional_info.owner_id, player.id})
    end

    {
      Map.put(projectiles_acc, projectile.id, projectile),
      Map.put(players_acc, player.id, player)
    }
  end

  # Projectile didn't collide
  defp apply_collision_updates(_, _, _, _, accs), do: accs

  defp decide_collided_entity(_projectile, [], _external_wall_id, _players), do: nil

  defp decide_collided_entity(_projectile, [entity_id], external_wall_id, _players)
       when entity_id == external_wall_id,
       do: external_wall_id

  defp decide_collided_entity(
         projectile,
         [entity_id | other_entities],
         _external_wall_id,
         _players
       )
       when entity_id == projectile.aditional_info.owner_id,
       do: List.first(other_entities, nil)

  defp decide_collided_entity(projectile, [entity_id | other_entities], external_wall_id, players) do
    player = Map.get(players, entity_id)

    case player && Player.alive?(player) do
      false -> decide_collided_entity(projectile, other_entities, external_wall_id, players)
      _ -> entity_id
    end
  end
end
