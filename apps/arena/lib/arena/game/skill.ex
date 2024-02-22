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
        {:trigger_mechanic, player.id, mechanic, skill_params},
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

  def do_mechanic(game_state, player, {:repeated_shot, repeated_shot}, skill_params) do
    remaining_amount = repeated_shot.amount - 1

    if remaining_amount > 0 do
      repeated_shot = Map.put(repeated_shot, :amount, remaining_amount)

      Process.send_after(
        self(),
        {:trigger_mechanic, player.id, {:repeated_shot, repeated_shot}, skill_params},
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
        skill_params.skill_key,
        repeated_shot
      )

    Process.send_after(self(), {:remove_projectile, projectile.id}, repeated_shot.duration_ms)

    game_state
    |> Map.put(:last_id, last_id)
    |> put_in([:projectiles, projectile.id], projectile)
  end

  def do_mechanic(game_state, player, {:multi_shoot, multishot}, skill_params) do
    calculate_angle_directions(multishot.amount, multishot.angle_between, player.direction)
    |> Enum.reduce(game_state, fn direction, game_state_acc ->
      last_id = game_state_acc.last_id + 1

      projectile =
        Entities.new_projectile(
          last_id,
          get_real_projectile_spawn_position(player, multishot),
          direction,
          player.id,
          skill_params.skill_key,
          multishot
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
        "SLINGSHOT",
        simple_shoot
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
