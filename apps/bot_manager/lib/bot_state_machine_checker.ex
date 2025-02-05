defmodule BotManager.BotStateMachineChecker do
  @moduledoc """
  This module will take care of deciding what the bot will do on each deciding step
  """
  alias BotManager.Utils

  @low_health_percentage 40
  @time_stuck_in_position 400

  defstruct [
    # The bot state, these are the possible states: [:idling, :moving, :attacking, :running_away, :tracking_player, :repositioning]
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
    # The time that the bot is going to take to change its position in milliseconds
    :time_amount_to_change_position,
    # The last time that the bot changed its position
    :last_time_position_changed,
    # The maximum vision range that the bot can follow a player
    :max_vision_range_to_follow_player,
    # The vision range that the bot has to find a player to attack
    :vision_range_to_attack_player,
    # Start Time in the same position
    :start_time_stuck_in_position,
    # The position that the bot is stuck in
    :stuck_in_position
  ]

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
      time_amount_to_change_position: 2000,
      last_time_position_changed: 0,
      max_vision_range_to_follow_player: 1500,
      vision_range_to_attack_player: 1200,
      stuck_in_position: nil,
      start_time_stuck_in_position: nil
    }
  end

  def move_to_next_state(bot_player, bot_state_machine, players) do
    cond do
      bot_stuck?(bot_state_machine) -> :moving
      bot_health_low?(bot_player) -> :running_away
      bot_can_follow_a_player?(bot_player, bot_state_machine, players) -> :tracking_player
      bot_can_turn_aggresive?(bot_state_machine) -> :attacking
      true -> :moving
    end
  end

  def should_bot_move_to_another_position?(bot_state_machine) do
    current_time = :os.system_time(:millisecond)
    time_since_last_position_change = current_time - bot_state_machine.last_time_position_changed

    time_since_last_position_change >= bot_state_machine.time_amount_to_change_position
  end

  defp bot_health_low?(bot_player) do
    {:player, bot_player_info} = bot_player.aditional_info
    health_percentage = bot_player_info.health * 100 / bot_player_info.max_health

    health_percentage <= @low_health_percentage
  end

  defp bot_can_turn_aggresive?(bot_state_machine) do
    bot_state_machine.progress_for_basic_skill >= bot_state_machine.cap_for_basic_skill ||
      bot_state_machine.progress_for_ultimate_skill >= bot_state_machine.cap_for_ultimate_skill
  end

  defp bot_can_follow_a_player?(bot_player, bot_state_machine, players) do
    players_nearby_to_follow =
      Utils.map_directions_to_players(players, bot_player, bot_state_machine.max_vision_range_to_follow_player)

    players_nearby_to_attack =
      Utils.map_directions_to_players(players, bot_player, bot_state_machine.vision_range_to_attack_player)

    Enum.empty?(players_nearby_to_attack) && not Enum.empty?(players_nearby_to_follow) &&
      bot_can_turn_aggresive?(bot_state_machine) && not bot_stuck?(bot_state_machine)
  end

  defp bot_stuck?(%{start_time_stuck_in_position: nil}), do: false

  defp bot_stuck?(bot_state_machine) do
    time_stuck = :os.system_time(:millisecond) - bot_state_machine.start_time_stuck_in_position
    time_stuck >= @time_stuck_in_position
  end
end
