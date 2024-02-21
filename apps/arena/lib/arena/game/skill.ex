defmodule Arena.Game.Skill do
  @moduledoc """
  Module for handling skills
  """
  alias Arena.Entities
  alias Arena.Game.Player

  def do_mechanic(game_state, player, mechanics, skill_params) when is_list(mechanics) do
    Enum.reduce(mechanics, game_state, fn mechanic, game_state_acc ->
      do_mechanic(game_state_acc, player, mechanic, skill_params)
    end)
  end

  def do_mechanic(game_state, player, {:circle_hit, circle_hit}, _skill_params) do
    circular_damage_area =
      Entities.make_circular_area(player.id, player.position, circle_hit.range)

    alive_players = Player.alive_players(game_state.players)

    players =
      Physics.check_collisions(circular_damage_area, alive_players)
      |> Enum.reduce(game_state.players, fn player_id, players_acc ->
        real_damage = Player.calculate_real_damage(player, circle_hit.damage)

        target_player =
          Map.get(players_acc, player_id)
          |> Player.take_damage(real_damage)

        send(self(), {:damage_done, player.id, circle_hit.damage})

        unless Player.alive?(target_player) do
          send(self(), {:to_killfeed, player.id, target_player.id})
        end

        Map.put(players_acc, player_id, target_player)
      end)

    %{game_state | players: players}
  end

  def do_mechanic(game_state, player, {:cone_hit, cone_hit}, _skill_params) do
    triangle_points =
      Physics.calculate_triangle_vertices(
        player.position,
        player.direction,
        cone_hit.range,
        cone_hit.angle
      )

    cone_area = Entities.make_polygon(player.id, triangle_points)

    alive_players = Map.filter(game_state.players, fn {_id, player} -> Player.alive?(player) end)

    players =
      Physics.check_collisions(cone_area, alive_players)
      |> Enum.reduce(game_state.players, fn player_id, players_acc ->
        real_damage = Player.calculate_real_damage(player, cone_hit.damage)

        target_player =
          Map.get(players_acc, player_id)
          |> Player.take_damage(real_damage)

        send(self(), {:damage_done, player.id, cone_hit.damage})

        unless Player.alive?(target_player) do
          send(self(), {:to_killfeed, player.id, target_player.id})
        end

        Map.put(players_acc, player_id, target_player)
      end)

    %{game_state | players: players}
  end

  def do_mechanic(game_state, player, {:multi_cone_hit, multi_cone_hit}, skill_params) do
    Enum.each(1..(multi_cone_hit.amount - 1), fn i ->
      mechanic = {:cone_hit, multi_cone_hit}

      Process.send_after(
        self(),
        {:trigger_mechanic, player.id, mechanic},
        i * multi_cone_hit.interval_ms
      )
    end)

    do_mechanic(game_state, player, {:cone_hit, multi_cone_hit}, skill_params)
  end

  def do_mechanic(game_state, player, {:dash, %{speed: speed, duration: duration}}, _skill_params) do
    Process.send_after(self(), {:stop_dash, player.id, player.speed}, duration)

    player =
      player
      |> Map.put(:is_moving, true)
      |> Map.put(:speed, speed)
      |> put_in([:aditional_info, :forced_movement], true)

    players = Map.put(game_state.players, player.id, player)

    %{game_state | players: players}
  end

  def do_mechanic(game_state, player, {:repeated_shot, repeated_shot}, _skill_params) do
    remaining_amount = repeated_shot.amount - 1

    if remaining_amount > 0 do
      repeated_shot = Map.put(repeated_shot, :amount, remaining_amount)

      Process.send_after(
        self(),
        {:trigger_mechanic, player.id, {:repeated_shot, repeated_shot}},
        repeated_shot.interval_ms
      )
    end

    last_id = game_state.last_id + 1

    projectile =
      Entities.new_projectile(
        last_id,
        get_real_projectile_spawn_position(player, repeated_shot),
        randomize_direction_in_angle(player.direction, repeated_shot.angle),
        player.id,
        repeated_shot.remove_on_collision,
        repeated_shot.speed
      )

    Process.send_after(self(), {:remove_projectile, projectile.id}, repeated_shot.duration_ms)

    game_state
    |> Map.put(:last_id, last_id)
    |> put_in([:projectiles, projectile.id], projectile)
  end

  def do_mechanic(game_state, player, {:multi_shoot, multishot}, _skill_params) do
    calculate_angle_directions(multishot.amount, multishot.angle_between, player.direction)
    |> Enum.reduce(game_state, fn direction, game_state_acc ->
      last_id = game_state_acc.last_id + 1

      projectile =
        Entities.new_projectile(
          last_id,
          get_real_projectile_spawn_position(player, multishot),
          direction,
          player.id,
          multishot.remove_on_collision,
          multishot.speed
        )

      Process.send_after(self(), {:remove_projectile, projectile.id}, multishot.duration_ms)

      game_state_acc
      |> Map.put(:last_id, last_id)
      |> put_in([:projectiles, projectile.id], projectile)
    end)
  end

  def do_mechanic(game_state, player, {:simple_shoot, simple_shoot}, _skill_params) do
    last_id = game_state.last_id + 1

    projectile =
      Entities.new_projectile(
        last_id,
        get_real_projectile_spawn_position(player, simple_shoot),
        player.direction,
        player.id,
        true,
        10.0
      )

    Process.send_after(self(), {:remove_projectile, projectile.id}, simple_shoot.duration_ms)

    game_state
    |> Map.put(:last_id, last_id)
    |> put_in([:projectiles, projectile.id], projectile)
  end

  def do_mechanic(game_state, player, {:leap, leap}, %{skill_direction: skill_direction}) do
    Process.send_after(
      self(),
      {:stop_leap, player.id, player.speed, leap.on_arrival_mechanic},
      leap.duration_ms
    )

    ## TODO: Cap target_position to leap.range
    target_position = %{
      x: player.position.x + skill_direction.x * leap.range,
      y: player.position.y + skill_direction.y * leap.range
    }

    ## TODO: Magic number needs to be replaced with state.game_config.game.tick_rate_ms
    speed = Physics.calculate_speed(player.position, target_position, leap.duration_ms) * 30

    player =
      player
      |> Map.put(:is_moving, true)
      |> Map.put(:speed, speed)
      |> put_in([:aditional_info, :forced_movement], true)

    put_in(game_state, [:players, player.id], player)
  end

  def do_mechanic(game_state, player, {:spawn_pool, pool_params}, %{
        skill_direction: skill_direction
      }) do
    last_id = game_state.last_id + 1

    target_position = %{
      x: player.position.x + skill_direction.x * pool_params.range,
      y: player.position.y + skill_direction.y * pool_params.range
    }

    pool =
      Entities.new_pool(
        last_id,
        target_position,
        pool_params.effects_to_apply,
        pool_params.radius,
        player.id
      )

    Process.send_after(self(), {:remove_pool, last_id}, pool_params.duration_ms)

    put_in(game_state, [:pools, last_id], pool)
    |> put_in([:last_id], last_id)
  end

  def handle_skill_effects(game_state, player, effects, game_config) do
    effects_to_apply =
      Enum.map(effects, fn effect_name ->
        Enum.find(game_config.effects, fn effect -> effect.name == effect_name end)
      end)

    effects =
      get_in(game_state, [:players, player.id, :aditional_info, :effects])
      |> Map.reject(fn {_, effect} -> effect.remove_on_action end)

    game_state = put_in(game_state, [:players, player.id, :aditional_info, :effects], effects)

    Enum.reduce(effects_to_apply, game_state, fn effect, game_state ->
      last_id = game_state.last_id + 1

      Process.send_after(self(), {:remove_effect, player.id, last_id}, effect.duration_ms)

      put_in(
        game_state,
        [:players, player.id, :aditional_info, :effects, last_id],
        Map.put(effect, :id, last_id)
      )
    end)
  end

  def apply_effect_mechanic(players, game_state) do
    updated_players =
      Map.filter(players, fn {_, player} -> Player.alive?(player) end)
      |> Enum.map(fn {_player_id, player} ->
        player =
          Enum.reduce(player.aditional_info.effects, player, fn {_effect_id, effect}, player ->
            apply_effect_mechanic(player, effect, game_state)
          end)

        {player.id, player}
      end)
      |> Map.new()

    Map.merge(players, updated_players)
  end

  def apply_effect_mechanic(player, effect, game_state) do
    now = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

    mechanics_to_apply =
      effect.effect_mechanics
      |> Map.filter(fn {_name, mechanic} ->
        now - Map.get(mechanic, :last_application_time, 0) >= mechanic.effect_delay_ms
      end)
      |> Enum.map(fn {name, mechanic} ->
        {name, Map.put(mechanic, :last_application_time, now)}
      end)
      |> Map.new()

    Enum.reduce(mechanics_to_apply, player, fn mechanic, player ->
      do_effect_mechanics(game_state, player, effect, mechanic)
    end)
    |> update_in([:aditional_info, :effects, effect.id, :effect_mechanics], fn mechanics ->
      Map.merge(mechanics, mechanics_to_apply)
    end)
  end

  defp do_effect_mechanics(game_state, player, effect, {:pull, pull_params}) do
    Map.get(game_state.pools, effect.owner_id)
    |> case do
      nil ->
        player

      pool ->
        if pool.position != player.position do
          direction = Physics.get_direction_from_positions(player.position, pool.position)

          rust_player = Physics.move_entity_to_direction(player, direction, pull_params.force)

          Map.put(rust_player, :aditional_info, player.aditional_info)
          |> Map.put(:collides_with, player.collides_with)
        else
          player
        end
    end
  end

  defp do_effect_mechanics(game_state, player, effect, {:damage, damage_params}) do
    Map.get(game_state.pools, effect.owner_id)
    |> case do
      nil ->
        player

      pool ->
        pool_owner = Map.get(game_state.players, pool.aditional_info.owner_id)
        real_damage = Player.calculate_real_damage(pool_owner, damage_params.damage)

        send(self(), {:damage_done, pool_owner.id, real_damage})

        player = Player.take_damage(player, real_damage)

        unless Player.alive?(player) do
          send(self(), {:to_killfeed, pool_owner.id, player.id})
        end

        player
    end
  end

  defp calculate_angle_directions(amount, angle_between, base_direction) do
    middle = if rem(amount, 2) == 1, do: [base_direction], else: []
    side_amount = div(amount, 2)
    angles = Enum.map(1..side_amount, fn i -> angle_between * i end)

    {add_side, sub_side} =
      Enum.reduce(angles, {[], []}, fn angle, {add_side_acc, sub_side_acc} ->
        add_side_acc = [Physics.add_angle_to_direction(base_direction, angle) | add_side_acc]
        sub_side_acc = [Physics.add_angle_to_direction(base_direction, -angle) | sub_side_acc]
        {add_side_acc, sub_side_acc}
      end)

    Enum.concat([add_side, middle, sub_side])
  end

  defp get_real_projectile_spawn_position(spawner, specs) do
    real_position_x = spawner.position.x + specs.projectile_offset * spawner.direction.x
    real_position_y = spawner.position.y + specs.projectile_offset * spawner.direction.y

    %{x: real_position_x, y: real_position_y}
  end

  defp randomize_direction_in_angle(direction, angle) do
    angle = :rand.uniform() * angle - angle / 2
    Physics.add_angle_to_direction(direction, angle)
  end

  def maybe_auto_aim(%{x: x, y: y} = _skill_direction, player, entities)
      when x == 0.0 and y == 0.0 do
    Physics.nearest_entity_direction(player, entities)
  end

  def maybe_auto_aim(skill_direction, _player, _entities) do
    skill_direction
  end
end
