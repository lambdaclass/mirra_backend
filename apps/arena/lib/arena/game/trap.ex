defmodule Arena.Game.Trap do
  @moduledoc """
  Module to handle traps logic
  """
  alias Arena.Game.Skill

  @doc """
  Apply all trap mechanics to an entity
  """
  def do_mechanics(game_state, entity, mechanics) do
    Enum.reduce(mechanics, game_state, fn mechanic, game_state_acc ->
      do_mechanic(game_state_acc, entity, mechanic)
    end)
  end

  @doc """
  Apply a trap mechanic to an entity, depending on the mechanic type.
  """
  def do_mechanic(game_state, entity, {:circle_hit, circle_hit}) do
    # We will be using the skill mechanic here until we abstract the attacks
    Skill.do_mechanic(game_state, entity, {:circle_hit, circle_hit}, %{})
  end
end
