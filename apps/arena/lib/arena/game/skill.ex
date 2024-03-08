defmodule Arena.Game.Skill do
  @moduledoc """
  Module for handling skills
  """
  alias Arena.{Entities, Utils}
  alias Arena.Game.Player

  def do_mechanic(game_state, entity, mechanics, skill_params) when is_list(mechanics) do
    Enum.reduce(mechanics, game_state, fn mechanic, game_state_acc ->
      do_mechanic(game_state_acc, entity, mechanic, skill_params)
    end)
  end

  def do_mechanic(game_state, entity, {:circle_hit, circle_hit}, _skill_params) do
    circular_damage_area = Entities.make_circular_area(entity.id, entity.position, circle_hit.range)

    entity_player_owner = get_entity_player_owner(game_state, entity)

    alive_players =
      Player.alive_players(game_state.players)
      |> Map.filter(fn {_, alive_player} -> alive_player.id != entity_player_owner.id end)

    players =
      Physics.check_collisions(circular_damage_area, alive_players)
      |> Enum.reduce(game_state.players, fn player_id, players_acc ->
        real_damage = Player.calculate_real_damage(entity_player_owner, circle_hit.damage)

        target_player =
          Map.get(players_acc, player_id)
          |> Player.take_damage(real_damage)

        send(self(), {:damage_done, entity_player_owner.id, circle_hit.damage})

        unless Player.alive?(target_player) do
          send(self(), {:to_killfeed, entity_player_owner.id, target_player.id})
        end

        Map.put(players_acc, player_id, target_player)
      end)

    %{game_state | players: players}
  end

  def do_mechanic(game_state, entity, {:cone_hit, cone_hit}, _skill_params) do
    triangle_points =
      Physics.calculate_triangle_vertices(
        entity.position,
        entity.direction,
        cone_hit.range,
        cone_hit.angle
      )

    cone_area = Entities.make_polygon(entity.id, triangle_points)

    alive_players = Map.filter(game_state.players, fn {_id, player} -> Player.alive?(player) end)

    players =
      Physics.check_collisions(cone_area, alive_players)
      |> Enum.reduce(game_state.players, fn player_id, players_acc ->
        entity_player_owner = get_entity_player_owner(game_state, entity)
        real_damage = Player.calculate_real_damage(entity_player_owner, cone_hit.damage)

        target_player =
          Map.get(players_acc, player_id)
          |> Player.take_damage(real_damage)

        send(self(), {:damage_done, entity_player_owner.id, cone_hit.damage})

        unless Player.alive?(target_player) do
          send(self(), {:to_killfeed, entity_player_owner.id, target_player.id})
        end

        Map.put(players_acc, player_id, target_player)
      end)

    %{game_state | players: players}
    |> maybe_move_player(entity, cone_hit[:move_by])
  end

  def do_mechanic(game_state, entity, {:multi_cone_hit, multi_cone_hit}, skill_params) do
    Enum.each(1..(multi_cone_hit.amount - 1), fn i ->
      mechanic = {:cone_hit, multi_cone_hit}

      Process.send_after(
        self(),
        {:trigger_mechanic, entity.id, mechanic, skill_params},
        i * multi_cone_hit.interval_ms
      )
    end)

    do_mechanic(game_state, entity, {:cone_hit, multi_cone_hit}, skill_params)
  end

  def do_mechanic(
        game_state,
        entity,
        {:dash, %{speed: speed, duration: duration}},
        _skill_params
      ) do
    Process.send_after(self(), {:stop_dash, entity.id, entity.speed}, duration)

    player =
      entity
      |> Map.put(:is_moving, true)
      |> Map.put(:speed, speed)
      |> put_in([:aditional_info, :forced_movement], true)

    players = Map.put(game_state.players, entity.id, player)

    %{game_state | players: players}
  end

  def do_mechanic(game_state, entity, {:repeated_shot, repeated_shot}, skill_params) do
    remaining_amount = repeated_shot.amount - 1

    if remaining_amount > 0 do
      repeated_shot = Map.put(repeated_shot, :amount, remaining_amount)

      Process.send_after(
        self(),
        {:trigger_mechanic, entity.id, {:repeated_shot, repeated_shot}, skill_params},
        repeated_shot.interval_ms
      )
    end

    entity_player_owner = get_entity_player_owner(game_state, entity)

    last_id = game_state.last_id + 1

    projectile =
      Entities.new_projectile(
        last_id,
        get_real_projectile_spawn_position(entity_player_owner, repeated_shot),
        randomize_direction_in_angle(entity.direction, repeated_shot.angle),
        entity_player_owner.id,
        skill_params.skill_key,
        repeated_shot
      )

    Process.send_after(self(), {:remove_projectile, projectile.id}, repeated_shot.duration_ms)

    game_state
    |> Map.put(:last_id, last_id)
    |> put_in([:projectiles, projectile.id], projectile)
  end

  def do_mechanic(game_state, entity, {:multi_shoot, multishot}, skill_params) do
    entity_player_owner = get_entity_player_owner(game_state, entity)

    calculate_angle_directions(multishot.amount, multishot.angle_between, entity.direction)
    |> Enum.reduce(game_state, fn direction, game_state_acc ->
      last_id = game_state_acc.last_id + 1

      projectile =
        Entities.new_projectile(
          last_id,
          get_real_projectile_spawn_position(entity_player_owner, multishot),
          direction,
          entity_player_owner.id,
          skill_params.skill_key,
          multishot
        )

      Process.send_after(self(), {:remove_projectile, projectile.id}, multishot.duration_ms)

      game_state_acc
      |> Map.put(:last_id, last_id)
      |> put_in([:projectiles, projectile.id], projectile)
    end)
  end

  def do_mechanic(game_state, entity, {:simple_shoot, simple_shoot}, skill_params) do
    last_id = game_state.last_id + 1
    entity_player_owner = get_entity_player_owner(game_state, entity)

    projectile =
      Entities.new_projectile(
        last_id,
        get_real_projectile_spawn_position(entity_player_owner, simple_shoot),
        entity.direction,
        entity_player_owner.id,
        skill_params.skill_key,
        simple_shoot
      )

    Process.send_after(self(), {:remove_projectile, projectile.id}, simple_shoot.duration_ms)

    game_state
    |> Map.put(:last_id, last_id)
    |> put_in([:projectiles, projectile.id], projectile)
  end

  def do_mechanic(game_state, entity, {:leap, leap}, %{skill_direction: skill_direction}) do
    Process.send_after(
      self(),
      {:stop_leap, entity.id, entity.speed, leap.on_arrival_mechanic},
      leap.duration_ms
    )

    ## TODO: Cap target_position to leap.range
    target_position = %{
      x: entity.position.x + skill_direction.x * leap.range,
      y: entity.position.y + skill_direction.y * leap.range
    }

    ## TODO: Magic number needs to be replaced with state.game_config.game.tick_rate_ms
    speed = Physics.calculate_speed(entity.position, target_position, leap.duration_ms) * 30

    player =
      entity
      |> Map.put(:is_moving, true)
      |> Map.put(:speed, speed)
      |> put_in([:aditional_info, :forced_movement], true)

    put_in(game_state, [:players, entity.id], player)
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

      effects =
        get_in(game_state, [:players, player.id, :aditional_info, :effects])
        |> Map.put(last_id, effect)

      put_in(game_state, [:players, player.id, :aditional_info, :effects], effects)
      |> put_in([:last_id], last_id)
    end)
  end

  defp calculate_angle_directions(amount, angle_between, base_direction) do
    base_direction_normalized = Utils.normalize(base_direction)
    middle = if rem(amount, 2) == 1, do: [base_direction_normalized], else: []
    side_amount = div(amount, 2)
    angles = Enum.map(1..side_amount, fn i -> angle_between * i end)

    {add_side, sub_side} =
      Enum.reduce(angles, {[], []}, fn angle, {add_side_acc, sub_side_acc} ->
        add_side_acc = [
          Physics.add_angle_to_direction(base_direction_normalized, angle) | add_side_acc
        ]

        sub_side_acc = [
          Physics.add_angle_to_direction(base_direction_normalized, -angle) | sub_side_acc
        ]

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

  def maybe_auto_aim(%{x: x, y: y}, skill, player, entities) when x == 0.0 and y == 0.0 do
    case skill.autoaim do
      true -> Physics.nearest_entity_direction(player, entities)
      false -> player.direction |> maybe_normalize(not skill.can_pick_destination)
    end
  end

  def maybe_auto_aim(skill_direction, skill, _player, _entities) do
    skill_direction |> maybe_normalize(not skill.can_pick_destination)
  end

  defp maybe_normalize(direction, true) do
    Utils.normalize(direction)
  end

  defp maybe_normalize(direction, _false) do
    direction
  end

  defp get_entity_player_owner(_game_state, %{category: :player} = player), do: player

  defp get_entity_player_owner(game_state, %{
         category: :projectile,
         aditional_info: %{owner_id: owner_id}
       }),
       do: get_in(game_state, [:players, owner_id])

  defp maybe_move_player(game_state, %{category: :player} = player, move_by)
       when not is_nil(move_by) do
    player_for_moving = %{player | is_moving: true, speed: move_by}

    physics_player = Physics.move_entity(player_for_moving, 1.0, game_state.external_wall, game_state.obstacles)

    player = Map.merge(player, %{physics_player | is_moving: false, speed: player.speed})
    put_in(game_state, [:players, player.id], player)
  end

  defp maybe_move_player(game_state, _, _) do
    game_state
  end
end
