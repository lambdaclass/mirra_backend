defmodule Champions.Config do
  @moduledoc """
  Configuration utilities.
  """

  alias GameBackend.Units.Characters

  @doc """
  Imports the characters configuration from 'characters.csv' in the app's priv folder.
  """
  def import_character_config() do
    [_headers | characters] =
      Application.app_dir(:champions, "priv/characters.csv")
      |> File.stream!()
      |> CSV.decode!()
      |> Enum.to_list()

    characters
    |> Enum.map(fn [name, class, faction, quality, attack, health, defense] ->
      %{
        name: name,
        class: class,
        faction: faction,
        quality: quality,
        base_attack: Integer.parse(attack) |> elem(0),
        base_health: Integer.parse(health) |> elem(0),
        base_armor: Integer.parse(defense) |> elem(0),
        game_id: 2,
        active: true
      }
    end)
    |> Characters.upsert_characters()
  end
end
