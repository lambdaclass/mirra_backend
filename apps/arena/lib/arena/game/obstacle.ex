defmodule Arena.Game.Obstacle do
  @moduledoc """
  Module to hable obstacles logic in game updater
  """

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
    now = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

    current_status_params =
      Map.get(obstacle.aditional_info.statuses_cycle, String.to_existing_atom(obstacle.aditional_info.status))

    update_in(obstacle, [:aditional_info], fn aditional_info ->
      aditional_info
      |> Map.put(:next_status, current_status_params.next_status)
      |> Map.put(:collisionable, current_status_params.make_obstacle_collisionable)
      |> Map.put(:time_until_transition_start, now + current_status_params.time_until_transition_ms)
    end)
  end

  def update_obstacle_transition_status(game_state, %{aditional_info: %{type: "dynamic"}} = obstacle) do
    now = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

    case obstacle.aditional_info.status do
      "transitioning" ->
        if obstacle.aditional_info.time_until_transition < now do
          handle_transition(game_state, obstacle.id)
        else
          game_state
        end

      _status ->
        if obstacle.aditional_info.time_until_transition_start < now do
          start_obstacle_transition(game_state, obstacle)
        else
          game_state
        end
    end
  end

  def update_obstacle_transition_status(game_state, _obstacle), do: game_state

  def start_obstacle_transition(game_state, obstacle) do
    next_status_params =
      Map.get(obstacle.aditional_info.statuses_cycle, String.to_existing_atom(obstacle.aditional_info.next_status))

    now = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

    obstacle =
      update_in(obstacle, [:aditional_info], fn aditional_info ->
        aditional_info
        |> Map.put(:status, "transitioning")
        |> Map.put(:time_until_transition, now + next_status_params.transition_time_ms)
      end)

    put_in(game_state, [:obstacles, obstacle.id], obstacle)
  end

  def handle_transition(game_state, obstacle_id) do
    obstacle = get_in(game_state, [:obstacles, obstacle_id])

    next_status_params =
      Map.get(obstacle.aditional_info.statuses_cycle, String.to_existing_atom(obstacle.aditional_info.next_status))

    now = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

    obstacle =
      update_in(obstacle, [:aditional_info], fn aditional_info ->
        aditional_info
        |> Map.put(:next_status, next_status_params.next_status)
        |> Map.put(:status, obstacle.aditional_info.next_status)
        |> Map.put(:collisionable, next_status_params.make_obstacle_collisionable)
        |> Map.put(:time_until_transition_start, now + next_status_params.time_until_transition_ms)
      end)

    Enum.reduce(next_status_params.on_activation_mechanics, game_state, fn mechanic, game_state ->
      Skill.do_mechanic(game_state, obstacle, mechanic, %{skill_direction: %{x: 0, y: 0}})
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
