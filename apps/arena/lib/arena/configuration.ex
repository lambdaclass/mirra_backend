defmodule Arena.Configuration do
  @moduledoc """
  Module in charge of configuration related things
  """

  def get_character_config(name, config) do
    Enum.find(config.characters, fn character -> character.name == name end)
  end

  def get_game_config() do
    {:ok, config_json} =
      Application.app_dir(:arena, "priv/config.json")
      |> File.read()

    config = Jason.decode!(config_json, [{:keys, :atoms}])
    skills = parse_skills_config(config.skills)
    characters = parse_characters_config(config.characters, skills)
    items = parse_items_config(config.items)
    %{config | skills: skills, characters: characters, items: items}
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
    |> Enum.map(&parse_mechanic_fields/1)
    |> hd()
  end

  defp parse_mechanic_fields({:leap, attrs}) do
    {:leap, %{attrs | on_arrival_mechanic: parse_mechanic_config(attrs.on_arrival_mechanic)}}
  end

  defp parse_mechanic_fields({name, %{on_explode_mechanics: on_explode_mechanics} = attrs}) do
    {name, %{attrs | on_explode_mechanics: parse_mechanic_config(on_explode_mechanics)}}
  end

  defp parse_mechanic_fields(mechanic) do
    mechanic
  end

  defp parse_characters_config(characters, config_skills) do
    Enum.map(characters, fn character ->
      character_skills =
        Enum.map(character.skills, fn {skill_key, skill_name} ->
          skill = find_skill!(skill_name, config_skills)
          {:erlang.atom_to_binary(skill_key), skill}
        end)
        |> Map.new()

      %{character | skills: character_skills}
    end)
  end

  defp find_skill!(skill_name, skills) do
    skill = Enum.find(skills, fn skill -> skill.name == skill_name end)

    ## This is a sanity check when loading the config
    if skill == nil do
      raise "Skill #{inspect(skill_name)} does not exist in config"
    else
      skill
    end
  end

  defp parse_items_config(items_config) do
    Enum.reduce(items_config, [], fn item_config, items ->
      effects = parse_effects_config(item_config.effects)
      item = %{item_config | effects: effects}
      [item | items]
    end)
  end

  defp parse_effects_config(effects_config) do
    Enum.reduce(effects_config, [], fn effect_config, acc ->
      effect = parse_effect_config(effect_config)
      [effect | acc]
    end)
  end

  defp parse_effect_config(effect) when map_size(effect) > 1 do
    raise "Config has effect with 2 values: #{inspect(effect)}"
  end

  defp parse_effect_config(effect) do
    Map.to_list(effect)
    |> hd()
  end
end
