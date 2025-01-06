defmodule BotManager.BotStateMachineChecker do
  @moduledoc """
  This module will take care of deciding what the bot will do on each deciding step
  """
  @low_leath_percentage 40
  defstruct [
    # The bot state, these are the possible states: [:idling, :moving, :attacking, :running_away]
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
    # The time that the bot is going to take to change its direction in milliseconds
    :time_to_change_direction,
    # The last time that the bot changed its direction
    :last_time_direction_changed,
    # The time that the bot has been moving in the same direction
    :current_time_in_direction
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
      time_to_change_direction: 1600,
      last_time_direction_changed: 0,
      current_time_in_direction: 0
    }
  end

  def move_to_next_state(bot_player, bot_state_machine) do
    cond do
      bot_health_low?(bot_player) -> :running_away
      bot_can_turn_aggresive?(bot_state_machine) -> :attacking
      true -> :moving
    end
  end

  def bot_health_low?(bot_player) do
    {:player, bot_player_info} = bot_player.aditional_info
    health_percentage = bot_player_info.health * 100 / bot_player_info.max_health

    health_percentage <= @low_leath_percentage
  end

  def bot_can_turn_aggresive?(bot_state_machine) do
    bot_state_machine.progress_for_basic_skill >= bot_state_machine.cap_for_basic_skill ||
      bot_state_machine.progress_for_ultimate_skill >= bot_state_machine.cap_for_ultimate_skill
  end

  def should_bot_rotate_its_direction?(bot_state_machine) do
    current_time = :os.system_time(:millisecond)
    time_since_last_direction_change = current_time - bot_state_machine.last_time_direction_changed

    time_since_last_direction_change >= bot_state_machine.time_to_change_direction
  end
end
