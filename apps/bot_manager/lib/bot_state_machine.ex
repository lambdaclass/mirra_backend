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
  @dash_skill_key "3"

  @type bot_player() :: %BotManager.Protobuf.Entity{}
  @type players() :: %{binary() => bot_player()}

  def decide_action(%{bots_enabled?: false, bot_state_machine: bot_state_machine}) do
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

    if System.get_env("PATHFINDING_TEST") == "true" do
      move(bot_player, bot_state_machine, game_state.zone.radius)
    else
      case next_state do
        :moving ->
          move(bot_player, bot_state_machine, game_state.zone.radius)

        :attacking ->
          use_skill(%{
            bot_player: bot_player,
            bot_state_machine: bot_state_machine,
            game_state: game_state,
            attack_blocked: attack_blocked,
            bot_skills: skills
          })

        :tracking_player ->
          track_player(game_state, bot_player, bot_state_machine)
      end
    end
  end

  def decide_action(%{bot_state_machine: bot_state_machine}),
    do: %{action: :idling, bot_state_machine: bot_state_machine}

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
          move(bot_player, bot_state_machine, game_state.zone.radius)
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
          move(bot_player, bot_state_machine, game_state.zone.radius)
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
        move(bot_player, bot_state_machine, game_state.zone.radius)
    end
  end

  # This function will determine the direction and action the bot will take.
  defp determine_player_move_action(bot_player, direction) do
    {:player, bot_player_info} = bot_player.aditional_info

    if System.get_env("PATHFINDING_TEST") == "true" do
      {:move, direction}
    else
      if Map.has_key?(bot_player_info.cooldowns, @dash_skill_key) do
        {:move, direction}
      else
        {:use_skill, @dash_skill_key, bot_player.direction}
      end
    end
  end

  defp track_player(game_state, bot_player, bot_state_machine) do
    players_with_distances =
      Utils.map_directions_to_players(
        game_state.players,
        bot_player,
        Utils.get_action_distance_based_on_action_type(
          bot_state_machine.is_melee,
          bot_state_machine.melee_tracking_range,
          bot_state_machine.ranged_tracking_range
        )
      )

    if Enum.empty?(players_with_distances) do
      move(bot_player, bot_state_machine, game_state.zone.radius)
    else
      closest_player = Enum.min_by(players_with_distances, & &1.distance)

      %{
        action: determine_player_move_action(bot_player, closest_player.direction),
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

    bot_state_machine =
      Map.put(bot_state_machine, :progress_for_basic_skill, bot_state_machine.progress_for_basic_skill + distance)

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

  defp move(bot_player, bot_state_machine, safe_zone_radius) do
    bot_state_machine = determine_position_to_move_to(bot_state_machine, safe_zone_radius)

    # TODO instead of using `get_distance_and_direction_to_positions, use the pathfinding module`
    if not is_nil(bot_state_machine.path_towards_position) and Enum.count(bot_state_machine.path_towards_position) > 0 do
      %{direction: direction} =
        Utils.get_distance_and_direction_to_positions(
          bot_state_machine.current_position,
          hd(bot_state_machine.path_towards_position)
        )


      %{
        action: determine_player_move_action(bot_player, direction),
        bot_state_machine: bot_state_machine
      }
    else
      %{direction: direction} =
        Utils.get_distance_and_direction_to_positions(
          bot_state_machine.current_position,
          %{x: 0, y: 0}
        )

      %{
        action: determine_player_move_action(bot_player, direction),
        bot_state_machine: bot_state_machine
      }
    end

  end

  defp determine_position_to_move_to(bot_state_machine, safe_zone_radius) do 
    cond do
      is_nil(bot_state_machine.position_to_move_to) ||
          not Utils.position_within_radius(bot_state_machine.position_to_move_to, safe_zone_radius) ->
        position_to_move_to = BotManager.Utils.random_position_within_safe_zone_radius(floor(safe_zone_radius))

        Map.put(bot_state_machine, :position_to_move_to, position_to_move_to)
        |> Map.put(:path_towards_position, Utils.find_path_towards_position(bot_state_machine.current_position, position_to_move_to))
        |> Map.put(:last_time_position_changed, :os.system_time(:millisecond))

      System.get_env("PATHFINDING_TEST") == "true" and BotStateMachineChecker.current_waypoint_reached?(bot_state_machine) ->
        IO.inspect("Waypoint Reached!")
        Map.put(bot_state_machine, :path_towards_position, tl(bot_state_machine.path_towards_position))

      System.get_env("PATHFINDING_TEST") == "true" and BotStateMachineChecker.current_waypoint_reached?(bot_state_machine) and BotStateMachineChecker.should_bot_move_to_another_position?(bot_state_machine) ->
        IO.inspect("Waypoint Reached but need to recalculate new path!")
        position_to_move_to = BotManager.Utils.random_position_within_safe_zone_radius(floor(safe_zone_radius))

        Map.put(bot_state_machine, :position_to_move_to, position_to_move_to)
        |> Map.put(:path_towards_position, Utils.find_path_towards_position(bot_state_machine.current_position, position_to_move_to))
        |> Map.put(:last_time_position_changed, :os.system_time(:millisecond))

      BotStateMachineChecker.should_bot_move_to_another_position?(bot_state_machine) ->
        position_to_move_to = BotManager.Utils.random_position_within_safe_zone_radius(floor(safe_zone_radius))

        Map.put(bot_state_machine, :position_to_move_to, position_to_move_to)
        |> Map.put(:last_time_position_changed, :os.system_time(:millisecond))

      true ->
        bot_state_machine
    end
  end
end
