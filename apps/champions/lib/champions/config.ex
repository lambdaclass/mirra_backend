defmodule Champions.Config do
  @moduledoc """
  Configuration utilities.
  """

  alias Champions.Units
  alias Champions.Utils
  alias GameBackend.Units.Characters
  alias GameBackend.Units.Skills

  @doc """
  Imports the skills configuration from 'skills.json' in the app's priv folder.
  """
  def import_skill_config() do
    {:ok, skills_json} =
      Application.app_dir(:champions, "priv/skills.json")
      |> File.read()

    Jason.decode!(skills_json, [{:keys, :atoms}])
    |> Skills.upsert_skills()
  end

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
    |> Enum.map(fn [
                     name,
                     quality,
                     ranks_dropped_in,
                     class,
                     faction,
                     attack,
                     health,
                     defense,
                     basic_skill,
                     ultimate_skill
                   ] ->
      %{
        name: name,
        quality: String.downcase(quality) |> String.to_atom() |> Units.get_quality(),
        ranks_dropped_in: String.split(ranks_dropped_in, "/"),
        class: class,
        faction: faction,
        base_attack: Integer.parse(attack) |> elem(0),
        base_health: Integer.parse(health) |> elem(0),
        base_defense: Integer.parse(defense) |> elem(0),
        game_id: Utils.game_id(),
        basic_skill_id: get_skill(basic_skill).id,
        ultimate_skill_id: get_skill(ultimate_skill).id,
        active: true
      }
    end)
    |> Characters.upsert_characters()
  end

  defp get_skill(skill_name) do
    with {:skill, skill} <- {:skill, Skills.get_skill_by_name(skill_name)} do
      skill
    end
  end
end
