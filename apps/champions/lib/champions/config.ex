defmodule Champions.Config do
  @moduledoc """
  Configuration utilities.
  """

  require Logger

  alias GameBackend.Units.Skills
  alias Champions.Units
  alias Champions.Utils
  alias GameBackend.Units.Characters

  def import_skill_config() do
    {:ok, skills_json} =
      Application.app_dir(:champions, "priv/skills.json")
      |> File.read()

    Jason.decode!(skills_json, [{:keys, :atoms}])
    |> Enum.reduce({0, 0}, fn attrs, {succesful, error} ->
      case Skills.insert_skill(attrs) do
        {:ok, _skill} ->
          {succesful + 1, error}

        {:error, _reason} ->
          Logger.error("Could not insert skill #{Map.get(attrs, :name)}")
          {succesful, error + 1}
      end
    end)
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
                     basic_skill_name,
                     ultimate_skill_name
                   ] ->
      basic_skill_id = Skills.get_skill_id_by_name(basic_skill_name)
      ultimate_skill_id = Skills.get_skill_id_by_name(ultimate_skill_name)

      if is_nil(basic_skill_id), do: Logger.error("Could not find skill #{basic_skill_name}")

      if is_nil(ultimate_skill_id),
        do: Logger.error("Could not find skill #{ultimate_skill_name}")

      %{
        name: name,
        quality: String.downcase(quality) |> String.to_atom() |> Units.get_quality(),
        ranks_dropped_in: String.split(ranks_dropped_in, "/"),
        class: class,
        faction: faction,
        base_attack: Integer.parse(attack) |> elem(0),
        base_health: Integer.parse(health) |> elem(0),
        base_armor: Integer.parse(defense) |> elem(0),
        game_id: Utils.game_id(),
        active: true,
        basic_skill_id: basic_skill_id,
        ultimate_skill_id: ultimate_skill_id
      }
    end)
    |> Characters.upsert_characters()
  end
end
