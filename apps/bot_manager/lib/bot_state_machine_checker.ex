defmodule BotManager.BotStateMachineChecker do
  defstruct [
    # The bot state, these are the possible states: [:idling, :moving, :aggresive, :running_away]
    :state,
    :previous_position,
    :current_position,
    # This is going to be charged every time the bot travels 10 units
    :progress_for_basic_skill,
    # This is going to be charged every time the bot uses the basic skill
    :progress_for_ultimate_skill,
    # This is the maximum value that the progress_for_basic_skill can reach
    :cap_for_basic_skill,
    # This is the maximum value that the progress_for_ultimate_skill can reach
    :cap_for_ultimate_skill
  ]

  def new do
    %BotManager.BotStateMachineChecker{
      state: :idling,
      progress_for_basic_skill: 0,
      progress_for_ultimate_skill: 0,
      cap_for_basic_skill: 100,
      cap_for_ultimate_skill: 3,
      previous_position: nil,
      current_position: nil
    }
  end

  def move_to_next_state(bot_player, bot_state_machine) do
    cond do
      bot_health_low?(bot_player) -> :running_away
      bot_can_turn_aggresive?(bot_state_machine) -> :aggresive
      true -> :moving
    end
  end

  def bot_health_low?(bot_player) do
    {:player, bot_player_info} = bot_player.aditional_info
    health_percentage = bot_player_info.health * 100 / bot_player_info.max_health

    health_percentage <= 20
  end

  def bot_can_turn_aggresive?(bot_state_machine) do
    bot_state_machine.progress_for_basic_skill >= bot_state_machine.cap_for_basic_skill ||
      bot_state_machine.progress_for_ultimate_skill >= bot_state_machine.cap_for_ultimate_skill
  end
end
