defmodule BotManager.BotStateMachine do
  @moduledoc """
  This module will take care of the bot state machine logic.
  """

  alias BotManager.BotStateMachineChecker
  alias BotManager.Utils
  alias BotManager.Math.Vector
  require Logger

  @skill_1_key "1"
  @skill_2_key "2"

  # The minimum distance a tracked player has to move for the tracking path to
  # get recalculated
  @path_recalculation_min_diff 300

  def decide_action(%{bots_enabled?: false, bot_state_machine: bot_state_machine}) do
    %{action: {:move, %{x: 0, y: 0}}, bot_state_machine: bot_state_machine}
  end

  def decide_action(%{bot_player: %{aditional_info: {:player, %{health: health}}}, bot_state_machine: bot_state_machine})
      when health <= 0 do
    %{action: {:move, %{x: 0, y: 0}}, bot_state_machine: bot_state_machine}
  end

  @doc """
  This function will decide the next action for the bot.
  """
  def decide_action(%{
        game_state: game_state,
        bot_player: bot_player,
        bot_state_machine: bot_state_machine,
        attack_blocked: attack_blocked,
        bot_skills: skills
      }) do
    bot_state_machine = preprocess_bot_state(bot_state_machine, bot_player)
    next_state = BotStateMachineChecker.move_to_next_state(bot_player, bot_state_machine, game_state.players)

    bot_state_machine = maybe_exit_state(bot_state_machine, next_state)

    case next_state do
      :moving ->
        move(bot_state_machine, game_state.zone.radius)

      :attacking ->
        use_skill(%{
          bot_player: bot_player,
          bot_state_machine: bot_state_machine,
          game_state: game_state,
          attack_blocked: attack_blocked,
          bot_skills: skills
        })

      :tracking_player ->
        bot_state_machine = maybe_set_tracking_path(game_state, bot_player, bot_state_machine)
        track_player(game_state, bot_player, bot_state_machine)
    end
  end

  def decide_action(%{bot_state_machine: bot_state_machine}),
    do: %{action: :idling, bot_state_machine: bot_state_machine}

  # This function will handle state switching logic to leave the bot state machine in a proper state
  defp maybe_exit_state(%{state: state} = bot_state_machine, state) do
    bot_state_machine
  end

  defp maybe_exit_state(%{state: state} = bot_state_machine, new_state) do
    bot_state_machine
    |> Map.put(:state, new_state)
    |> Map.put(:last_time_state_changed, :os.system_time(:millisecond))
    |> exit_state(state)
  end

  # updates necessary data to exit each specific state
  defp exit_state(bot_state_machine, :tracking_player) do
    bot_state_machine
    |> Map.put(:last_time_tracking_exited, :os.system_time(:millisecond))
  end

  defp exit_state(bot_state_machine, :attacking) do
    bot_state_machine
    |> Map.put(:last_time_attacking_exited, :os.system_time(:millisecond))
  end

  defp exit_state(bot_state_machine, _exited_state) do
    bot_state_machine
  end

  @doc """
  This function will be in charge of using the bot's skill.
  Depending on the bot's state, it will use the basic skill, the ultimate skill or move.
  """
  def use_skill(%{attack_blocked: true, bot_player: bot_player, bot_state_machine: bot_state_machine}),
    do: %{action: {:move, bot_player.direction}, bot_state_machine: bot_state_machine}

  def use_skill(%{
        game_state: game_state,
        bot_player: bot_player,
        bot_state_machine: bot_state_machine,
        bot_skills: skills
      }) do
    cond do
      bot_state_machine.progress_for_ultimate_skill >= bot_state_machine.cap_for_ultimate_skill ->
        players_with_distances =
          Utils.map_directions_to_players(
            game_state.players,
            bot_player,
            Utils.get_action_distance_based_on_action_type(
              skills.ultimate.attack_type,
              bot_state_machine.melee_attack_distance,
              bot_state_machine.ranged_attack_distance
            )
          )

        if Enum.empty?(players_with_distances) do
          move(bot_state_machine, game_state.zone.radius)
        else
          bot_state_machine =
            Map.put(
              bot_state_machine,
              :progress_for_ultimate_skill,
              bot_state_machine.progress_for_ultimate_skill - bot_state_machine.cap_for_ultimate_skill
            )

          direction = maybe_aim_to_a_player(bot_player, players_with_distances)

          %{action: {:use_skill, @skill_2_key, direction}, bot_state_machine: bot_state_machine}
        end

      bot_state_machine.progress_for_basic_skill >= bot_state_machine.cap_for_basic_skill ->
        players_with_distances =
          Utils.map_directions_to_players(
            game_state.players,
            bot_player,
            Utils.get_action_distance_based_on_action_type(
              skills.basic.attack_type,
              bot_state_machine.melee_attack_distance,
              bot_state_machine.ranged_attack_distance
            )
          )

        if Enum.empty?(players_with_distances) do
          move(bot_state_machine, game_state.zone.radius)
        else
          bot_state_machine =
            Map.put(
              bot_state_machine,
              :progress_for_basic_skill,
              bot_state_machine.progress_for_basic_skill - bot_state_machine.cap_for_basic_skill
            )
            |> Map.put(:progress_for_ultimate_skill, bot_state_machine.progress_for_ultimate_skill + 1)

          direction = maybe_aim_to_a_player(bot_player, players_with_distances)

          %{action: {:use_skill, @skill_1_key, direction}, bot_state_machine: bot_state_machine}
        end

      true ->
        move(bot_state_machine, game_state.zone.radius)
    end
  end

  defp maybe_set_tracking_path(game_state, bot_player, bot_state_machine) do
    players_with_distances =
      Utils.map_directions_to_players(
        game_state.players,
        bot_player,
        Utils.get_action_distance_by_type(
          bot_state_machine.is_melee,
          bot_state_machine.melee_tracking_range,
          bot_state_machine.ranged_tracking_range
        )
      )

    closest_player = Enum.min_by(players_with_distances, & &1.distance)

    cond do
      is_nil(bot_state_machine.path_towards_position) or Enum.empty?(bot_state_machine.path_towards_position) or
          Vector.distance(bot_state_machine.position_to_move_to, closest_player.position) > @path_recalculation_min_diff ->
        try_pathing_towards(bot_state_machine, closest_player.position)

      BotStateMachineChecker.current_waypoint_reached?(bot_state_machine) ->
        Map.put(bot_state_machine, :path_towards_position, tl(bot_state_machine.path_towards_position))

      true ->
        bot_state_machine
    end
  end

  defp track_player(game_state, bot_player, bot_state_machine) do
    if is_nil(bot_state_machine.path_towards_position) || Enum.empty?(bot_state_machine.path_towards_position) do
      move(bot_state_machine, game_state.zone.radius)
    else
      current_waypoint = hd(bot_state_machine.path_towards_position)

      direction =
        Vector.sub(current_waypoint, bot_player.position)
        |> Vector.normalize()

      %{
        action: {:move, direction},
        bot_state_machine: bot_state_machine
      }
    end
  end

  defp preprocess_bot_state(bot_state_machine, bot_player) do
    bot_state_machine =
      if is_nil(bot_state_machine.previous_position) do
        bot_state_machine
        |> Map.put(:previous_position, bot_player.position)
        |> Map.put(:current_position, bot_player.position)
      else
        bot_state_machine
        |> Map.put(:previous_position, bot_state_machine.current_position)
        |> Map.put(:current_position, bot_player.position)
      end

    %{distance: distance} =
      Utils.get_distance_and_direction_to_positions(
        bot_state_machine.previous_position,
        bot_state_machine.current_position
      )

    new_progress = min(bot_state_machine.cap_for_basic_skill * 3, bot_state_machine.progress_for_basic_skill + distance)

    bot_state_machine =
      Map.put(bot_state_machine, :progress_for_basic_skill, new_progress)

    cond do
      Vector.distance(bot_state_machine.previous_position, bot_state_machine.current_position) < 100 &&
          is_nil(bot_state_machine.start_time_stuck_in_position) ->
        Map.put(bot_state_machine, :start_time_stuck_in_position, :os.system_time(:millisecond))
        |> Map.put(:stuck_in_position, bot_state_machine.current_position)

      not is_nil(bot_state_machine.stuck_in_position) &&
          Vector.distance(bot_state_machine.stuck_in_position, bot_state_machine.current_position) > 100 ->
        Map.put(bot_state_machine, :start_time_stuck_in_position, nil)
        |> Map.put(:stuck_in_position, nil)

      true ->
        bot_state_machine
    end
  end

  defp maybe_aim_to_a_player(bot_player, players_with_distances) do
    if Enum.empty?(players_with_distances) do
      bot_player.direction
    else
      closest_player = Enum.min_by(players_with_distances, & &1.distance)
      closest_player.direction
    end
  end

  defp move(bot_state_machine, safe_zone_radius) do
    bot_state_machine =
      determine_position_to_move_to(bot_state_machine, safe_zone_radius)

    # TODO instead of using `get_distance_and_direction_to_positions, use the pathfinding module`
    cond do
      not is_nil(bot_state_machine.path_towards_position) and Enum.count(bot_state_machine.path_towards_position) > 0 ->
        %{direction: direction} =
          Utils.get_distance_and_direction_to_positions(
            bot_state_machine.current_position,
            hd(bot_state_machine.path_towards_position)
          )

        %{
          action: {:move, direction},
          bot_state_machine: bot_state_machine
        }

      not is_nil(bot_state_machine.position_to_move_to) ->
        %{direction: direction} =
          Utils.get_distance_and_direction_to_positions(
            bot_state_machine.current_position,
            bot_state_machine.position_to_move_to
          )

        %{
          action: {:move, direction},
          bot_state_machine: bot_state_machine
        }

      true ->
        %{
          action: :idling,
          bot_state_machine: bot_state_machine
        }
    end
  end

  defp determine_position_to_move_to(%{collision_grid: nil} = bot_state_machine, _safe_zone_radius) do
    bot_state_machine
  end

  defp determine_position_to_move_to(bot_state_machine, safe_zone_radius) do
    cond do
      is_nil(bot_state_machine.path_towards_position) || Enum.empty?(bot_state_machine.path_towards_position) ||
          Vector.distance(%{x: 0, y: 0}, bot_state_machine.position_to_move_to) > safe_zone_radius ->
        try_pick_random_position_to_move_to(bot_state_machine, safe_zone_radius)

      BotStateMachineChecker.current_waypoint_reached?(bot_state_machine) and
          BotStateMachineChecker.should_bot_move_to_another_position?(bot_state_machine) ->
        try_pick_random_position_to_move_to(bot_state_machine, safe_zone_radius)

      BotStateMachineChecker.current_waypoint_reached?(bot_state_machine) ->
        Map.put(bot_state_machine, :path_towards_position, tl(bot_state_machine.path_towards_position))

      true ->
        bot_state_machine
    end
  end

  defp try_pick_random_position_to_move_to(bot_state_machine, safe_zone_radius) do
    position_to_move_to = BotManager.Utils.random_position_within_safe_zone_radius(floor(safe_zone_radius))

    try_pathing_towards(bot_state_machine, position_to_move_to)
  end

  defp try_pathing_towards(bot_state_machine, position_to_move_to) do
    from = %{x: bot_state_machine.current_position.x, y: bot_state_machine.current_position.y}
    to = %{x: position_to_move_to.x, y: position_to_move_to.y}

    shortest_path = AStarNative.a_star_shortest_path(from, to, bot_state_machine.collision_grid)

    # If we don't have a path, retry finding new position in map
    cond do
      Enum.empty?(shortest_path) ->
        Map.put(bot_state_machine, :path_towards_position, nil)
        |> Map.put(:position_to_move_to, nil)

      length(shortest_path) == 1 ->
        Map.put(bot_state_machine, :position_to_move_to, position_to_move_to)
        |> Map.put(
          :path_towards_position,
          [to]
        )
        |> Map.put(:last_time_position_changed, :os.system_time(:millisecond))

      true ->
        # Replacing first and last points with the actual start and end points
        shortest_path =
          ([from] ++ Enum.slice(shortest_path, 1, Enum.count(shortest_path) - 2) ++ [to])
          |> AStarNative.simplify_path(bot_state_machine.obstacles)

        shortest_path =
          if System.get_env("TEST_PATHFINDING_SPLINES") == "true" do
            shortest_path
            |> SplinePath.smooth_path()
          else
            shortest_path
          end

        # The first point should only be necessary to simplify the path
        shortest_path = tl(shortest_path)

        Map.put(bot_state_machine, :position_to_move_to, position_to_move_to)
        |> Map.put(
          :path_towards_position,
          shortest_path
        )
        |> Map.put(:last_time_position_changed, :os.system_time(:millisecond))
    end
  end
end
