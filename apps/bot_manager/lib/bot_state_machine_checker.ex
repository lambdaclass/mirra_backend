defmodule BotManager.BotStateMachineChecker do
  @moduledoc """
  This module will take care of deciding what the bot will do on each deciding step
  """
  alias BotManager.Utils
  alias BotManager.Math.Vector

  @time_stuck_in_position 400
  @distance_threshold 100

  @type state_step() :: :attacking | :moving | :tracking_player | :idling

  @type t :: %BotManager.BotStateMachineChecker{
          state: state_step(),
          previous_position: map() | nil,
          current_position: map() | nil,
          progress_for_basic_skill: integer(),
          progress_for_ultimate_skill: integer(),
          cap_for_basic_skill: integer(),
          cap_for_ultimate_skill: integer(),
          position_to_move_to: map() | nil,
          path_towards_position: list() | nil,
          time_amount_to_change_position: integer(),
          last_time_position_changed: integer(),
          stuck_in_position: map() | nil,
          start_time_stuck_in_position: integer() | nil,
          melee_tracking_range: integer(),
          ranged_tracking_range: integer(),
          ranged_attack_distance: integer(),
          melee_attack_distance: integer(),
          is_melee: boolean() | nil
        }

  defstruct [
    # The bot state, these are the possible states: [:idling, :moving, :attacking, :tracking_player]
    :state,
    # The previous position of the bot
    :previous_position,
    # The current position of the bot
    :current_position,
    # This is going to be charged every time the bot travels 10 units
    :progress_for_basic_skill,
    # This is going to be charged every time the bot uses the basic skill
    :progress_for_ultimate_skill,
    # This is the maximum value that the progress_for_basic_skill can reach
    :cap_for_basic_skill,
    # This is the maximum value that the progress_for_ultimate_skill can reach
    :cap_for_ultimate_skill,
    # The position that the bot is going to move to
    :position_to_move_to,
    # The path that the bot is following
    :path_towards_position,
    # The time that the bot is going to take to change its position in milliseconds
    :time_amount_to_change_position,
    # The last time that the bot changed its position
    :last_time_position_changed,
    # Start Time in the same position
    :start_time_stuck_in_position,
    # The position that the bot is stuck in
    :stuck_in_position,
    # The range that the bot has to follow a player in melee
    :melee_tracking_range,
    # The range that the bot has to follow a player in ranged
    :ranged_tracking_range,
    # The range that the bot has to attack a player
    :ranged_attack_distance,
    # The range that the bot has to attack a player in melee
    :melee_attack_distance,
    # The type of attack that the bot has
    :is_melee
  ]

  @spec new() :: BotManager.BotStateMachineChecker.t()
  def new do
    %BotManager.BotStateMachineChecker{
      state: :idling,
      progress_for_basic_skill: 0,
      progress_for_ultimate_skill: 0,
      cap_for_basic_skill: 100,
      cap_for_ultimate_skill: 3,
      previous_position: nil,
      current_position: nil,
      position_to_move_to: nil,
      path_towards_position: nil,
      time_amount_to_change_position: 2000,
      last_time_position_changed: 0,
      stuck_in_position: nil,
      start_time_stuck_in_position: nil,
      melee_tracking_range: 2000,
      ranged_tracking_range: 1500,
      ranged_attack_distance: 1200,
      melee_attack_distance: 300,
      is_melee: nil
    }
  end

  @spec move_to_next_state(
          BotManager.BotStateMachine.bot_player(),
          BotManager.BotStateMachineChecker.t(),
          BotManager.BotStateMachine.players()
        ) :: state_step()
  def move_to_next_state(bot_player, bot_state_machine, players) do
    # TODO: force :moving
    cond do
      # bot_stuck?(bot_state_machine) -> :moving
      # bot_can_follow_a_player?(bot_player, bot_state_machine, players) -> :tracking_player
      # bot_can_turn_aggresive?(bot_state_machine) -> :attacking
      true -> :moving
    end
  end

  @spec should_bot_move_to_another_position?(BotManager.BotStateMachineChecker.t()) :: boolean()
  def should_bot_move_to_another_position?(bot_state_machine) do
    is_nil(bot_state_machine.path_towards_position) or Enum.count(bot_state_machine.path_towards_position) <= 1
  end

  @spec current_waypoint_reached?(BotManager.BotStateMachineChecker.t()) :: boolean()
  def current_waypoint_reached?(bot_state_machine) do
    # Change position if we're close enough
    end_position = hd(bot_state_machine.path_towards_position)
    base_position = bot_state_machine.current_position
    %{x: x, y: y} = Vector.sub(end_position, base_position)

    distance = Vector.norm(%{x: x, y: y})

    distance <= @distance_threshold
  end

  @spec bot_can_turn_aggresive?(BotManager.BotStateMachineChecker.t()) :: boolean()
  defp bot_can_turn_aggresive?(bot_state_machine) do
    bot_state_machine.progress_for_basic_skill >= bot_state_machine.cap_for_basic_skill ||
      bot_state_machine.progress_for_ultimate_skill >= bot_state_machine.cap_for_ultimate_skill
  end

  @spec bot_can_follow_a_player?(
          BotManager.BotStateMachine.bot_player(),
          BotManager.BotStateMachineChecker.t(),
          BotManager.BotStateMachine.players()
        ) :: boolean()
  defp bot_can_follow_a_player?(bot_player, bot_state_machine, players) do
    players_nearby_to_follow =
      Utils.map_directions_to_players(
        players,
        bot_player,
        Utils.get_action_distance_by_type(
          bot_state_machine.is_melee,
          bot_state_machine.melee_attack_distance,
          bot_state_machine.ranged_attack_distance
        )
      )

    players_nearby_to_attack =
      Utils.map_directions_to_players(
        players,
        bot_player,
        Utils.get_action_distance_by_type(
          bot_state_machine.is_melee,
          bot_state_machine.melee_attack_distance,
          bot_state_machine.ranged_attack_distance
        )
      )

    Enum.empty?(players_nearby_to_attack) && not Enum.empty?(players_nearby_to_follow) &&
      bot_can_turn_aggresive?(bot_state_machine) && not bot_stuck?(bot_state_machine)
  end

  @spec bot_stuck?(BotManager.BotStateMachineChecker.t()) :: boolean()
  defp bot_stuck?(%{start_time_stuck_in_position: nil}), do: false

  defp bot_stuck?(bot_state_machine) do
    time_stuck = :os.system_time(:millisecond) - bot_state_machine.start_time_stuck_in_position
    time_stuck >= @time_stuck_in_position
  end
end
