defmodule BotManager.BotStateMachineChecker do
  defstruct [
    # The bot state, these are the possible states: [:idling, :moving, :attacking, :running_away]
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
end
