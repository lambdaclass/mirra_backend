defmodule Arena.Game.Obstacle do
  alias Arena.Game.Skill
  alias Arena.Entities
  alias Arena.Game.Player

  def collisionable_obstacle?(obstacle) do
    obstacle.aditional_info.collisionable
  end

  def get_collisionable_obstacles(obstacles) do
    Map.filter(obstacles, fn {_obstacle_id, obstacle} -> collisionable_obstacle?(obstacle) end)
  end

  def handle_transition_init(obstacle) do
    current_status_params =
      Map.get(obstacle.aditional_info.statuses_cycle, String.to_existing_atom(obstacle.aditional_info.status))

    Process.send_after(
      self(),
      {:start_obstacle_transition, obstacle.id},
      current_status_params.time_until_transition_ms
    )

    update_in(obstacle, [:aditional_info], fn aditional_info ->
      aditional_info
      |> Map.put(:next_status, current_status_params.next_status)
      |> Map.put(:collisionable, current_status_params.make_obstacle_collisionable)
    end)
  end

  def start_obstacle_transition(obstacle) do
    next_status_params =
      Map.get(obstacle.aditional_info.statuses_cycle, String.to_existing_atom(obstacle.aditional_info.next_status))

    Process.send_after(
      self(),
      {:handle_obstacle_transition, obstacle.id},
      next_status_params.transition_time_ms
    )

    update_in(obstacle, [:aditional_info], fn aditional_info ->
      aditional_info
      |> Map.put(:status, "transitioning")
    end)
  end

  def handle_transition(game_state, obstacle_id) do
    obstacle = get_in(game_state, [:obstacles, obstacle_id])

    next_status_params =
      Map.get(obstacle.aditional_info.statuses_cycle, String.to_existing_atom(obstacle.aditional_info.next_status))

    Process.send_after(
      self(),
      {:start_obstacle_transition, obstacle.id},
      next_status_params.time_until_transition_ms
    )

    obstacle =
      update_in(obstacle, [:aditional_info], fn aditional_info ->
        aditional_info
        |> Map.put(:next_status, next_status_params.next_status)
        |> Map.put(:status, obstacle.aditional_info.next_status)
        |> Map.put(:collisionable, next_status_params.make_obstacle_collisionable)
      end)

    Enum.reduce(next_status_params.on_activation_mechanics, game_state, fn mechanic, game_state ->
      Skill.do_mechanic(game_state, obstacle, mechanic, %{})
    end)
    |> put_in([:obstacles, obstacle.id], obstacle)
    |> maybe_move_above_players(obstacle_id)
  end

  defp maybe_move_above_players(game_state, obstacle_id) do
    obstacle = get_in(game_state, [:obstacles, obstacle_id])

    if collisionable_obstacle?(obstacle) do
      obstacle_area = Entities.make_polygon_area(obstacle.id, obstacle.vertices)

      alive_players =
        Player.alive_players(game_state.players)

      players =
        Physics.check_collisions(obstacle_area, alive_players)
        |> Enum.reduce(game_state.players, fn player_id, players_acc ->
          player = Map.get(players_acc, player_id)

          new_position =
            Physics.get_closest_available_position(
              player.position,
              player,
              game_state.external_wall,
              game_state.obstacles
            )

          updated_player =
            Map.put(player, :position, new_position)

          Map.put(players_acc, player_id, updated_player)
        end)

      %{game_state | players: players}
    else
      game_state
    end
  end
end
