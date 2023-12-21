defmodule DarkWorldsServer.Utils.Characters do
  def character_name_to_game_character_name("h4ck"), do: "H4ck"
  def character_name_to_game_character_name("muflus"), do: "Muflus"

  def game_character_name_to_character_name("H4ck"), do: "h4ck"
  def game_character_name_to_character_name("Muflus"), do: "muflus"
end
