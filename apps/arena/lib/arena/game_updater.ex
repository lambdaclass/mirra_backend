defmodule Arena.GameUpdater do
  @moduledoc """
  GenServer that broadcasts the latest game update to every client
  (player websocket).
  """

  use GenServer
  alias Arena.{Configuration, Entities}
  alias Arena.Game.{Player, Skill}
  alias Arena.Serialization.{GameEvent, GameState, GameFinished}
  alias Phoenix.PubSub

  ##########################
  # API
  ##########################
  def join(game_pid, client_id) do
    GenServer.call(game_pid, {:join, client_id})
  end

  def move(game_pid, player_id, direction, timestamp) do
    GenServer.call(game_pid, {:move, player_id, direction, timestamp})
  end

  def attack(game_pid, player_id, skill, skill_params, timestamp) do
    GenServer.call(game_pid, {:attack, player_id, skill, skill_params, timestamp})
  end

  def use_item(game_pid, player_id, timestamp) do
    GenServer.call(game_pid, {:use_item, player_id, timestamp})
  end

  ##########################
  # END API
  ##########################

  def init(%{clients: clients}) do
    game_id = self() |> :erlang.term_to_binary() |> Base58.encode()
    game_config = Configuration.get_game_config()
    game_state = new_game(game_id, clients, game_config)

    send(self(), :update_game)
    Process.send_after(self(), :game_start, game_config.game.start_game_time_ms)

    {:ok, %{game_config: game_config, game_state: game_state}}
  end

  ##########################
  # API Callbacks
  ##########################

  def handle_call({:move, player_id, direction, timestamp}, _from, state) do
    player =
      state.game_state.players
      |> Map.get(player_id)
      |> Player.move(direction)

    game_state =
      state.game_state
      |> put_in([:players, player_id], player)
      |> put_in([:player_timestamps, player_id], timestamp)

    {:reply, :ok, %{state | game_state: game_state}}
  end

  def handle_call({:attack, player_id, skill_key, skill_params, timestamp}, _from, state) do
    broadcast_player_block_actions(state.game_state.game_id, player_id, true)

    game_state =
      get_in(state, [:game_state, :players, player_id])
      |> Player.use_skill(skill_key, skill_params, state)
      |> put_in([:player_timestamps, player_id], timestamp)

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

  def handle_call({:use_item, player_id, _timestamp}, _from, state) do
    game_state =
      get_in(state, [:game_state, :players, player_id])
      |> Player.use_item(state.game_state)

    {:reply, :ok, %{state | game_state: game_state}}
  end

  ##########################
  # END API Callbacks
  ##########################

  ##########################
  # Game Callbacks
  ##########################

  def handle_info(:update_game, %{game_state: game_state} = state) do
    Process.send_after(self(), :update_game, state.game_config.game.tick_rate_ms)
    now = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
    time_diff = now - game_state.server_timestamp
    ticks_to_move = time_diff / state.game_config.game.tick_rate_ms

    game_state =
      game_state
      |> Map.put(:ticks_to_move, ticks_to_move)
      |> reduce_players_cooldowns(time_diff)
      |> move_players()
      |> update_projectiles_status()
      |> move_projectiles()
      |> resolve_players_collisions_with_power_ups()
      |> resolve_players_collisions_with_items()
      |> resolve_projectiles_collisions_with_players()
      |> apply_zone_damage_to_players(state.game_config.game)
      |> explode_projectiles()
      |> handle_pools(state.game_config)
      |> Skill.apply_effect_mechanic()
      |> Map.put(:server_timestamp, now)

    broadcast_game_update(game_state)
    game_state = %{game_state | killfeed: [], damage_taken: %{}, damage_done: %{}}

    {:noreply, %{state | game_state: game_state}}
  end

  def handle_info(:game_start, state) do
    broadcast_enable_incomming_messages(state.game_state.game_id)
    Process.send_after(self(), :start_zone_shrink, state.game_config.game.zone_shrink_start_ms)
    Process.send_after(self(), :spawn_item, state.game_config.game.item_spawn_interval_ms)
    send(self(), :natural_healing)
    send(self(), {:end_game_check, Map.keys(state.game_state.players)})

    {:noreply, put_in(state, [:game_state, :status], :RUNNING)}
  end

  def handle_info({:end_game_check, last_players_ids}, state) do
    case check_game_ended(state.game_state.players, last_players_ids) do
      {:ongoing, players_ids} ->
        Process.send_after(
          self(),
          {:end_game_check, players_ids},
          state.game_config.game.end_game_interval_ms
        )

      {:ended, winner} ->
        state = put_in(state, [:game_state, :status], :ENDED)
        broadcast_game_ended(winner, state.game_state)

        ## The idea of having this waiting period is in case websocket processes keep
        ## sending messages, this way we give some time before making them crash
        ## (sending to inexistant process will cause them to crash)
        Process.send_after(self(), :game_ended, state.game_config.game.shutdown_game_wait_ms)
    end

    {:noreply, state}
  end

  # Shutdown
  def handle_info(:game_ended, state) do
    {:stop, :normal, state}
  end

  ##########################
  # End Game Callbacks
  ##########################

  ##########################
  # Skill Callbacks
  ##########################

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
      |> Player.reset_forced_movement(previous_speed)

    state = put_in(state, [:game_state, :players, player_id], player)
    {:noreply, state}
  end

  def handle_info({:stop_leap, player_id, previous_speed, on_arrival_mechanic}, state) do
    player =
      Map.get(state.game_state.players, player_id)
      |> Player.reset_forced_movement(previous_speed)

    game_state =
      put_in(state.game_state, [:players, player_id], player)
      |> Skill.do_mechanic(player, on_arrival_mechanic, %{})

    {:noreply, %{state | game_state: game_state}}
  end

  def handle_info({:stop_stamina_faster, player_id, revert_by}, state) do
    player = Map.get(state.game_state.players, player_id)

    %{stamina_interval: max_stamina_interval} =
      Configuration.get_character_config(player.aditional_info.character_name, state.game_config)

    player = Player.revert_stamina_interval(player, revert_by, max_stamina_interval)
    state = put_in(state, [:game_state, :players, player.id], player)
    {:noreply, state}
  end

  def handle_info({:trigger_mechanic, player_id, mechanic, skill_params}, state) do
    player = Map.get(state.game_state.players, player_id)
    game_state = Skill.do_mechanic(state.game_state, player, mechanic, skill_params)
    state = Map.put(state, :game_state, game_state)
    {:noreply, state}
  end

  def handle_info({:delayed_skill_mechanics, player_id, mechanics, skill_params}, state) do
    player = Map.get(state.game_state.players, player_id)
    game_state = Skill.do_mechanic(state.game_state, player, mechanics, skill_params)
    {:noreply, %{state | game_state: game_state}}
  end

  def handle_info(
        {:delayed_effect_application, _player_id, nil},
        state
      ) do
    {:noreply, state}
  end

  def handle_info(
        {:delayed_effect_application, player_id, effects_to_apply},
        %{
          game_state: game_state,
          game_config: game_config
        } = state
      ) do
    player = Map.get(game_state.players, player_id)
    game_state = Skill.handle_skill_effects(game_state, player, effects_to_apply, game_config)
    {:noreply, %{state | game_state: game_state}}
  end

  # Natural healing
  def handle_info(:natural_healing, state) do
    Process.send_after(
      self(),
      :natural_healing,
      state.game_config.game.natural_healing_interval_ms
    )

    players = Player.trigger_natural_healings(state.game_state.players)
    state = put_in(state, [:game_state, :players], players)
    {:noreply, state}
  end

  ##########################
  # End Skill Callbacks
  ##########################

  ##########################
  # Zone Callbacks
  ##########################

  def handle_info(:start_zone_shrink, state) do
    Process.send_after(self(), :stop_zone_shrink, state.game_config.game.zone_stop_interval_ms)
    send(self(), :zone_shrink)

    now = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

    state =
      put_in(state, [:game_state, :zone, :shrinking], true)
      |> put_in([:game_state, :zone, :enabled], true)
      |> put_in(
        [:game_state, :zone, :next_zone_change_timestamp],
        now + state.game_config.game.zone_stop_interval_ms
      )

    {:noreply, state}
  end

  def handle_info(:stop_zone_shrink, state) do
    Process.send_after(self(), :start_zone_shrink, state.game_config.game.zone_start_interval_ms)

    now = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

    state =
      put_in(state, [:game_state, :zone, :shrinking], false)
      |> put_in(
        [:game_state, :zone, :next_zone_change_timestamp],
        now + state.game_config.game.zone_start_interval_ms
      )

    {:noreply, state}
  end

  def handle_info(:zone_shrink, %{game_state: %{zone: %{shrinking: true}}} = state) do
    Process.send_after(self(), :zone_shrink, state.game_config.game.zone_shrink_interval)
    radius = max(state.game_state.zone.radius - state.game_config.game.zone_shrink_radius_by, 0.0)
    state = put_in(state, [:game_state, :zone, :radius], radius)
    {:noreply, state}
  end

  def handle_info(:zone_shrink, %{game_state: %{zone: %{shrinking: false}}} = state) do
    {:noreply, state}
  end

  ##########################
  # End Zone Callbacks
  ##########################

  def handle_info(
        {:to_killfeed, killer_id, victim_id},
        %{game_state: game_state, game_config: game_config} = state
      ) do
    entry = %{killer_id: killer_id, victim_id: victim_id}
    victim = Map.get(game_state.players, victim_id)

    amount_of_power_ups = get_amount_of_power_ups(victim, game_config.power_ups.power_ups_per_kill)

    state =
      update_in(state, [:game_state, :killfeed], fn killfeed -> [entry | killfeed] end)
      |> update_in([:game_state, :players, killer_id, :aditional_info, :kill_count], fn count ->
        count + 1
      end)
      |> spawn_power_ups(victim, amount_of_power_ups)

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
            :EXPIRED
          )

        {:noreply, state}

      _ ->
        {:noreply, state}
    end
  end

  def handle_info(:spawn_item, state) do
    Process.send_after(self(), :spawn_item, state.game_config.game.item_spawn_interval_ms)

    last_id = state.game_state.last_id + 1
    ## TODO: make random position
    position =
      random_position_in_map(
        state.game_state.external_wall.radius,
        state.game_state.external_wall
      )

    item_config = Enum.random(state.game_config.items)
    item = Entities.new_item(last_id, position, item_config)

    state =
      put_in(state, [:game_state, :last_id], last_id)
      |> put_in([:game_state, :items, item.id], item)

    {:noreply, state}
  end

  def handle_info({:remove_speed_boost, player_id, amount}, state) do
    player =
      Map.get(state.game_state.players, player_id)
      |> Player.change_speed(-amount)

    state = put_in(state, [:game_state, :players, player_id], player)
    {:noreply, state}
  end

  def handle_info({:remove_damage_immunity, player_id}, state) do
    player =
      Map.get(state.game_state.players, player_id)
      |> Player.remove_damage_immunity()

    state = put_in(state, [:game_state, :players, player_id], player)
    {:noreply, state}
  end

  def handle_info({:block_actions, player_id}, state) do
    broadcast_player_block_actions(state.game_state.game_id, player_id, false)
    {:noreply, state}
  end

  def handle_info({:remove_effect, player_id, effect_id}, state) do
    case Map.get(state.game_state.players, player_id) do
      %{aditional_info: %{effects: %{^effect_id => _effect} = effects}} ->
        state =
          put_in(
            state,
            [:game_state, :players, player_id, :aditional_info, :effects],
            Map.delete(effects, effect_id)
          )

        {:noreply, state}

      _ ->
        {:noreply, state}
    end
  end

  def handle_info({:remove_pool, pool_id}, %{game_state: game_state} = state) do
    game_state =
      Enum.reduce(game_state.players, game_state, fn {_player_id, player}, game_state ->
        remove_pool_effects(game_state, player, pool_id)
      end)
      |> update_in(
        [:pools],
        fn current_pools ->
          Map.delete(current_pools, pool_id)
        end
      )

    {:noreply, %{state | game_state: game_state}}
  end

  ##########################
  # End callbacks
  ##########################

  ##########################
  # Broadcast
  ##########################

  defp broadcast_player_block_actions(game_id, player_id, value) do
    PubSub.broadcast(Arena.PubSub, game_id, {:block_actions, player_id, value})
  end

  # Broadcast game update to all players
  defp broadcast_player_dead(game_id, player_id) do
    PubSub.broadcast(Arena.PubSub, game_id, {:player_dead, player_id})
  end

  defp broadcast_enable_incomming_messages(game_id) do
    PubSub.broadcast(Arena.PubSub, game_id, :enable_incomming_messages)
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
             power_ups: complete_entities(state.power_ups),
             pools: complete_entities(state.pools),
             items: complete_entities(state.items),
             server_timestamp: state.server_timestamp,
             player_timestamps: state.player_timestamps,
             zone: state.zone,
             killfeed: state.killfeed,
             damage_taken: state.damage_taken,
             damage_done: state.damage_done,
             status: state.status,
             start_game_timestamp: state.start_game_timestamp
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
    |> Map.put(:name, entity.name)
    |> Map.put(:aditional_info, entity |> Entities.maybe_add_custom_info())
  end

  ##########################
  # End broadcast
  ##########################

  ##########################
  # Game Initialization
  ##########################

  # Create a new game
  defp new_game(game_id, clients, config) do
    now = System.monotonic_time(:millisecond)
    initial_timestamp = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

    new_game =
      Map.new(game_id: game_id)
      |> Map.put(:last_id, 0)
      |> Map.put(:players, %{})
      |> Map.put(:power_ups, %{})
      |> Map.put(:projectiles, %{})
      |> Map.put(:items, %{})
      |> Map.put(:player_timestamps, %{})
      |> Map.put(:server_timestamp, 0)
      |> Map.put(:client_to_player_map, %{})
      |> Map.put(:pools, %{})
      |> Map.put(:killfeed, [])
      |> Map.put(:damage_taken, %{})
      |> Map.put(:damage_done, %{})
      |> Map.put(:external_wall, Entities.new_external_wall(0, config.map.radius))
      |> Map.put(:zone, %{
        radius: config.map.radius,
        enabled: false,
        shrinking: false,
        next_zone_change_timestamp:
          initial_timestamp + config.game.zone_shrink_start_ms + config.game.start_game_time_ms
      })
      |> Map.put(:status, :PREPARING)
      |> Map.put(:start_game_timestamp, initial_timestamp + config.game.start_game_time_ms)

    {game, _} =
      Enum.reduce(clients, {new_game, config.map.initial_positions}, fn {client_id, character_name, player_name,
                                                                         _from_pid},
                                                                        {new_game, positions} ->
        last_id = new_game.last_id + 1
        {pos, positions} = get_next_position(positions)
        direction = Physics.get_direction_from_positions(pos, %{x: 0.0, y: 0.0})

        players =
          new_game.players
          |> Map.put(
            last_id,
            Entities.new_player(last_id, character_name, player_name, pos, direction, config, now)
          )

        new_game =
          new_game
          |> Map.put(:last_id, last_id)
          |> Map.put(:players, players)
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
        Map.put(
          obstacles_acc,
          last_id,
          Entities.new_circular_obstacle(last_id, obstacle.position, obstacle.radius)
        )

      {obstacles_acc, last_id}
    end)
  end

  ##########################
  # End Game Initialization
  ##########################

  ##########################
  # Game flow. Actions executed in every tick.
  ##########################

  defp reduce_players_cooldowns(game_state, time_diff) do
    players =
      Map.new(game_state.players, fn {player_id, player} ->
        cooldowns =
          Map.new(player.aditional_info.cooldowns, fn {skill_key, cooldown} ->
            {skill_key, cooldown - time_diff}
          end)
          |> Map.filter(fn {_skill_key, cooldown} -> cooldown > 0 end)

        player = put_in(player, [:aditional_info, :cooldowns], cooldowns)
        {player_id, player}
      end)

    %{game_state | players: players}
  end

  defp move_players(
         %{
           players: players,
           ticks_to_move: ticks_to_move,
           external_wall: external_wall,
           obstacles: obstacles,
           power_ups: power_ups,
           pools: pools,
           items: items
         } = game_state
       ) do
    entities_to_collide = Map.merge(power_ups, pools) |> Map.merge(items)

    moved_players =
      players
      |> Physics.move_entities(
        ticks_to_move,
        external_wall,
        obstacles
      )
      |> update_collisions(players, entities_to_collide)

    %{game_state | players: moved_players}
  end

  # Remove exploded projectiles
  # Update expired to explode status
  defp update_projectiles_status(%{projectiles: projectiles} = game_state) do
    updated_projectiles =
      Enum.reduce(projectiles, projectiles, fn {projectile_id, projectile}, acc ->
        case projectile.aditional_info.status do
          :EXPLODED ->
            Map.delete(acc, projectile_id)

          :EXPIRED ->
            Map.put(acc, projectile_id, put_in(projectile, [:aditional_info, :status], :EXPLODED))

          _ ->
            acc
        end
      end)

    %{game_state | projectiles: updated_projectiles}
  end

  defp move_projectiles(
         %{
           projectiles: projectiles,
           players: players,
           obstacles: obstacles,
           external_wall: external_wall,
           ticks_to_move: ticks_to_move
         } = game_state
       ) do
    # We don't want to move recently exploded projectiles
    {recently_exploded_projectiles, alive_projectiles} =
      projectiles
      |> Map.split_with(fn {_projectile_id, projectile} ->
        projectile.aditional_info.status == :EXPLODED
      end)

    entities_to_collide_with =
      Player.alive_players(players)
      |> Map.merge(obstacles)
      |> Map.merge(%{external_wall.id => external_wall})

    moved_projectiles =
      alive_projectiles
      |> Physics.move_entities(ticks_to_move, external_wall, %{})
      |> update_collisions(
        projectiles,
        entities_to_collide_with
      )
      |> Map.merge(recently_exploded_projectiles)

    %{game_state | projectiles: moved_projectiles}
  end

  defp resolve_players_collisions_with_power_ups(%{players: players, power_ups: power_ups} = game_state) do
    {updated_players, updated_power_ups} =
      Enum.reduce(players, {players, power_ups}, fn {_player_id, player}, {players_acc, power_ups_acc} ->
        case find_collided_power_up(player.collides_with, power_ups_acc) do
          nil ->
            {players_acc, power_ups_acc}

          power_up_id ->
            power_up = Map.get(power_ups_acc, power_up_id)
            process_power_up(player, power_up, players_acc, power_ups_acc)
        end
      end)

    game_state
    |> Map.put(:players, updated_players)
    |> Map.put(:power_ups, updated_power_ups)
  end

  defp resolve_players_collisions_with_items(game_state) do
    {players, items} =
      Enum.reduce(game_state.players, {game_state.players, game_state.items}, fn {_player_id, player},
                                                                                 {players_acc, items_acc} ->
        case find_collided_item(player.collides_with, items_acc) do
          nil ->
            {players_acc, items_acc}

          item ->
            process_item(player, item, players_acc, items_acc)
        end
      end)

    game_state
    |> Map.put(:players, players)
    |> Map.put(:items, items)
  end

  # This method will decide what to do when a projectile has collided with something in the map
  # - If collided with something with the same owner skip that collision
  # - If collided with external wall or obstacle explode projectile
  # - If collided with another player do the projectile's damage
  # - Do nothing on unexpected cases
  defp resolve_projectiles_collisions_with_players(
         %{
           projectiles: projectiles,
           players: players,
           obstacles: obstacles,
           external_wall: external_wall
         } = game_state
       ) do
    {updated_projectiles, updated_players} =
      Enum.reduce(projectiles, {projectiles, players}, fn {_projectile_id, projectile},
                                                          {_projectiles_acc, players_acc} = accs ->
        # check if the projectiles is inside the walls
        collides_with =
          case projectile.collides_with do
            [] -> [external_wall.id]
            entities -> List.delete(entities, external_wall.id)
          end

        collided_entity = decide_collided_entity(projectile, collides_with, external_wall.id, players_acc)

        process_projectile_collision(
          projectile,
          Map.get(players, collided_entity),
          Map.get(obstacles, collided_entity),
          collided_entity == external_wall.id,
          accs
        )
      end)

    game_state
    |> Map.put(:projectiles, updated_projectiles)
    |> Map.put(:players, updated_players)
  end

  defp explode_projectiles(%{projectiles: projectiles} = game_state) do
    Enum.reduce(projectiles, game_state, fn {_projectile_id, projectile}, game_state ->
      if projectile.aditional_info.status == :EXPLODED &&
           Map.get(projectile.aditional_info, :on_explode_mechanics) do
        Skill.do_mechanic(
          game_state,
          projectile,
          projectile.aditional_info.on_explode_mechanics,
          %{}
        )
      else
        game_state
      end
    end)
  end

  defp apply_zone_damage_to_players(%{players: players, zone: zone} = game_state, %{
         zone_damage_interval_ms: zone_interval,
         zone_damage: zone_damage
       }) do
    safe_zone = Entities.make_circular_area(0, %{x: 0.0, y: 0.0}, zone.radius)
    safe_ids = Physics.check_collisions(safe_zone, players)
    to_damage_ids = Map.keys(players) -- safe_ids
    now = System.monotonic_time(:millisecond)

    updated_players =
      Enum.reduce(to_damage_ids, players, fn player_id, players_acc ->
        player = Map.get(players_acc, player_id)
        last_damage = player |> get_in([:aditional_info, :last_damage_received])
        elapse_time = now - last_damage

        player = player |> maybe_receive_zone_damage(elapse_time, zone_interval, zone_damage)

        Map.put(players_acc, player_id, player)
      end)

    %{game_state | players: updated_players}
  end

  ##########################
  # End Game Flow
  ##########################

  ##########################
  # Helpers
  ##########################

  defp get_next_position([pos | rest]) do
    positions = rest ++ [pos]
    {pos, positions}
  end

  # Check entities collisions
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

  defp maybe_receive_zone_damage(player, elapse_time, zone_damage_interval, zone_damage)
       when elapse_time > zone_damage_interval do
    Player.take_damage(player, zone_damage)
  end

  defp maybe_receive_zone_damage(player, _elaptime, _zone_damage_interval, _zone_damage),
    do: player

  # Function to process the projectile collision with other entities
  defp process_projectile_collision(
         projectile,
         player,
         obstacle,
         collided_with_external_wall?,
         accs
       )

  # Projectile collided an obstacle or went outside of the arena
  defp process_projectile_collision(
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
  defp process_projectile_collision(projectile, player, _, _, {projectiles_acc, players_acc})
       when not is_nil(player) do
    attacking_player = Map.get(players_acc, projectile.aditional_info.owner_id)
    real_damage = Player.calculate_real_damage(attacking_player, projectile.aditional_info.damage)
    player = Player.take_damage(player, real_damage)

    send(
      self(),
      {:damage_done, projectile.aditional_info.owner_id, real_damage}
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

  # Projectile didn't collide at all
  defp process_projectile_collision(_, _, _, _, accs), do: accs

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

  defp spawn_power_ups(
         %{game_config: game_config} = state,
         victim,
         amount
       ) do
    distance_to_power_up = game_config.power_ups.power_up.distance_to_power_up

    Enum.reduce(1..amount//1, state, fn _, state ->
      random_x =
        victim.position.x +
          Enum.random(-distance_to_power_up..distance_to_power_up)

      random_y =
        victim.position.y +
          Enum.random(-distance_to_power_up..distance_to_power_up)

      random_position = %{x: random_x, y: random_y}
      last_id = state.game_state.last_id + 1

      power_up =
        Entities.new_power_up(
          last_id,
          random_position,
          victim.direction,
          victim.id,
          game_config.power_ups.power_up
        )

      put_in(state, [:game_state, :power_ups, last_id], power_up)
      |> put_in([:game_state, :last_id], last_id)
    end)
  end

  defp get_amount_of_power_ups(%{aditional_info: %{power_ups: power_ups}}, power_ups_per_kill) do
    Enum.sort_by(power_ups_per_kill, fn %{minimum_amount: minimum} -> minimum end, :desc)
    |> Enum.find(fn %{minimum_amount: minimum} ->
      minimum <= power_ups
    end)
    |> case do
      %{amount_of_drops: amount} -> amount
      _ -> 0
    end
  end

  defp find_collided_power_up(collides_with, power_ups) do
    Enum.find(collides_with, fn collided_entity_id ->
      Map.has_key?(power_ups, collided_entity_id)
    end)
  end

  defp find_collided_item(collides_with, items) do
    Enum.find_value(collides_with, fn collided_entity_id ->
      Map.get(items, collided_entity_id)
    end)
  end

  defp process_power_up(player, power_up, players_acc, power_ups_acc) do
    if power_up.aditional_info.status == :AVAILABLE && Player.alive?(player) do
      updated_power_up = put_in(power_up, [:aditional_info, :status], :TAKEN)

      updated_player = update_in(player, [:aditional_info, :power_ups], fn amount -> amount + 1 end)

      {Map.put(players_acc, player.id, updated_player), Map.put(power_ups_acc, power_up.id, updated_power_up)}
    else
      {players_acc, power_ups_acc}
    end
  end

  defp handle_pools(%{players: players} = game_state, game_config) do
    Enum.reduce(players, game_state, fn {_player_id, player}, game_state ->
      Enum.reduce(game_state.pools, game_state, fn {pool_id, pool}, acc ->
        if pool_id in player.collides_with do
          add_pool_effects(acc, game_config, player, pool)
        else
          remove_pool_effects(acc, player, pool_id)
        end
      end)
    end)
  end

  defp add_pool_effects(game_state, game_config, player, pool) do
    player_contain_pool_effects? =
      Enum.any?(player.aditional_info.effects, fn {_effect_id, effect} ->
        effect.owner_id == pool.id
      end)

    if player_contain_pool_effects? or player.id == pool.aditional_info.owner_id do
      game_state
    else
      Enum.reduce(pool.aditional_info.effects_to_apply, game_state, fn effect_name, game_state ->
        last_id = game_state.last_id + 1

        effect = Enum.find(game_config.effects, fn effect -> effect.name == effect_name end)

        game_state
        |> put_in(
          [:players, player.id, :aditional_info, :effects, last_id],
          Map.put(effect, :owner_id, pool.id)
          |> Map.put(:id, last_id)
        )
        |> put_in([:last_id], last_id)
      end)
    end
  end

  defp remove_pool_effects(game_state, player, pool_id) do
    update_in(game_state, [:players, player.id, :aditional_info, :effects], fn current_effects ->
      Map.reject(current_effects, fn {_effect_id, effect} -> effect.owner_id == pool_id end)
    end)
  end

  defp process_item(player, item, players_acc, items_acc) do
    if Player.inventory_full?(player) do
      {players_acc, items_acc}
    else
      player = Player.store_item(player, item.aditional_info)
      {Map.put(players_acc, player.id, player), Map.delete(items_acc, item.id)}
    end
  end

  defp random_position_in_map(radius, external_wall) do
    integer_radius = trunc(radius)
    x = Enum.random(-integer_radius..integer_radius) / 1.0
    y = Enum.random(-integer_radius..integer_radius) / 1.0

    point = %{
      id: 1,
      shape: :point,
      position: %{x: x, y: y},
      radius: 0.0,
      vertices: [],
      speed: 0.0,
      category: :obstacle,
      direction: %{x: 0.0, y: 0.0},
      is_moving: false
    }

    case Physics.check_collisions(point, %{0 => external_wall}) do
      [] -> random_position_in_map(integer_radius * 0.95, external_wall)
      _ -> point.position
    end
  end

  ##########################
  # End Helpers
  ##########################
end
