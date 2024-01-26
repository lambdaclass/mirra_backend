defmodule Arena.Configuration do
  @moduledoc """
  Module in charge of configuration related things
  """

  def get_game_config() do
    {:ok, config_json} =
      Application.app_dir(:arena, "priv/config.json")
      |> File.read()

    config = Jason.decode!(config_json, [{:keys, :atoms}])
    skills = parse_skills_config(config.skills)
    characters = parse_characters_config(config.characters, skills)
    %{config | skills: skills, characters: characters} |> IO.inspect()
  end

  defp parse_skills_config(skills_config) do
    Enum.reduce(skills_config, [], fn skill_config, skills ->
      mechanics = parse_mechanics_config(skill_config.mechanics)
      skill = %{skill_config | mechanics: mechanics}
      [skill | skills]
    end)
  end

  defp parse_mechanics_config(mechanics_config) do
    Enum.reduce(mechanics_config, [], fn mechanic_config, acc ->
      mechanic = parse_mechanic_config(mechanic_config)
      [mechanic | acc]
    end)
  end

  defp parse_mechanic_config(mechanic) when map_size(mechanic) > 1 do
    raise "Config has mechanic with 2 values: #{inspect(mechanic)}"
  end

  defp parse_mechanic_config(mechanic) do
    Map.to_list(mechanic)
    |> hd()
  end

  defp parse_characters_config(characters, skills) do
    Enum.map(characters, fn character ->
      character_skills =
        Enum.map(character.skills, fn {skill_key, skill_name} ->
          skill = Enum.find(skills, fn skill -> skill.name == skill_name end)

          ## This is a sanity check when loading the config
          if skill == nil do
            raise "Character #{inspect character.name} skill #{inspect skill_name} does not exist in config"
          end

          {:erlang.atom_to_binary(skill_key), skill}
        end)
        |> Map.new()

      %{character | skills: character_skills}
    end)
  end
end
