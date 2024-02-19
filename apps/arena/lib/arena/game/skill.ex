defmodule Arena.Game.Skill do
  @moduledoc """
  Module for handling skills
  """
  alias Arena.Entities
  alias Arena.Game.Player

  def do_mechanic(game_state, player, mechanics) when is_list(mechanics) do
    Enum.reduce(mechanics, game_state, fn mechanic, game_state_acc ->
      do_mechanic(game_state_acc, player, mechanic)
    end)
  end

  def do_mechanic(game_state, player, {:circle_hit, circle_hit}) do
    circular_damage_area =
      Entities.make_circular_area(player.id, player.position, circle_hit.range)

    alive_players = Player.alive_players(game_state.players)

    players =
      Physics.check_collisions(circular_damage_area, alive_players)
      |> Enum.reduce(game_state.players, fn player_id, players_acc ->
        target_player =
          Map.get(players_acc, player_id)
          |> Player.take_damage(circle_hit.damage)

        send(self(), {:damage_done, player.id, circle_hit.damage})

        unless Player.alive?(target_player) do
          send(self(), {:to_killfeed, player.id, target_player.id})
        end

        Map.put(players_acc, player_id, target_player)
      end)

    %{game_state | players: players}
  end

  def do_mechanic(game_state, player, {:cone_hit, cone_hit}) do
    Process.send_after(self(), {:trigger_mechanic, player.id, {:do_cone_hit, cone_hit}}, 300)
    game_state
  end

  def do_mechanic(game_state, player, {:do_cone_hit, cone_hit}) do
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
        target_player =
          Map.get(players_acc, player_id)
          |> Player.take_damage(cone_hit.damage)

        send(self(), {:damage_done, player.id, cone_hit.damage})

        unless Player.alive?(target_player) do
          send(self(), {:to_killfeed, player.id, target_player.id})
        end

        Map.put(players_acc, player_id, target_player)
      end)

    %{game_state | players: players}
  end

  def do_mechanic(game_state, player, {:multi_cone_hit, multi_cone_hit}) do
    Enum.each(1..(multi_cone_hit.amount - 1), fn i ->
      mechanic = {:do_cone_hit, multi_cone_hit}

      Process.send_after(
        self(),
        {:trigger_mechanic, player.id, mechanic},
        i * multi_cone_hit.interval_ms
      )
    end)

    do_mechanic(game_state, player, {:do_cone_hit, multi_cone_hit})
  end

  def do_mechanic(game_state, player, {:dash, %{speed: speed, duration: duration}}) do
    Process.send_after(self(), {:stop_dash, player.id, player.speed}, duration)

    player =
      player
      |> Map.put(:is_moving, true)
      |> Map.put(:speed, speed)

    players = Map.put(game_state.players, player.id, player)

    %{game_state | players: players}
  end

  def do_mechanic(game_state, player, {:repeated_shoot, repeated_shoot}) do
    Process.send_after(
      self(),
      {:repeated_shoot, player.id, repeated_shoot.interval_ms, repeated_shoot.amount - 1,
       repeated_shoot.remove_on_collision, repeated_shoot.speed},
      repeated_shoot.interval_ms
    )

    last_id = game_state.last_id + 1

    projectiles =
      game_state.projectiles
      |> Map.put(
        last_id,
        Entities.new_projectile(
          last_id,
          player.position,
          player.direction,
          player.id,
          repeated_shoot.remove_on_collision,
          repeated_shoot.speed
        )
      )

    game_state
    |> Map.put(:last_id, last_id)
    |> Map.put(:projectiles, projectiles)
  end

  def do_mechanic(game_state, player, {:multi_shoot, multishot}) do
    calculate_angle_directions(multishot.amount, multishot.angle_between, player.direction)
    |> Enum.reduce(game_state, fn direction, game_state_acc ->
      last_id = game_state_acc.last_id + 1

      projectiles =
        game_state_acc.projectiles
        |> Map.put(
          last_id,
          Entities.new_projectile(
            last_id,
            player.position,
            direction,
            player.id,
            multishot.remove_on_collision,
            multishot.speed
          )
        )

      game_state_acc
      |> Map.put(:last_id, last_id)
      |> Map.put(:projectiles, projectiles)
    end)
  end

  def do_mechanic(game_state, player, {:simple_shoot, _}) do
    last_id = game_state.last_id + 1

    projectiles =
      game_state.projectiles
      |> Map.put(
        last_id,
        Entities.new_projectile(
          last_id,
          player.position,
          player.direction,
          player.id,
          true,
          10.0
        )
      )

    game_state
    |> Map.put(:last_id, last_id)
    |> Map.put(:projectiles, projectiles)
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
end
