defmodule Arena.Game.Trap do
  @moduledoc """
  Module to handle traps logic
  """
  alias Arena.Game.Skill

  @doc """
  Apply a trap mechanic to an entity, depending on the mechanic type.
  """
  def do_mechanic(game_state, entity, %{type: "circle_hit"} = circle_hit) do
    # We will be using the skill mechanic here until we abstract the attacks
    Skill.do_mechanic(game_state, entity, circle_hit, %{skill_direction: entity.direction})
  end
end
