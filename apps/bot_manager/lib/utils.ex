defmodule BotManager.Utils do
  @moduledoc """
  utils to work with nested game state operations
  """

  def player_alive?(%{aditional_info: {:player, %{health: health}}}), do: health > 0

  def player_alive?(_), do: :not_a_player

  def list_character_skills_from_config(character_name, characters) do
    character = Enum.find(characters, fn character -> character.name == character_name end)
    {_id, basic} = Enum.find(character.skills, fn {_id, skill} -> skill.skill_type == :BASIC end)
    {_id, ultimate} = Enum.find(character.skills, fn {_id, skill} -> skill.skill_type == :ULTIMATE end)
    {_id, dash} = Enum.find(character.skills, fn {_id, skill} -> skill.skill_type == :DASH end)

    %{
      basic: basic,
      ultimate: ultimate,
      dash: dash
    }
  end
end
