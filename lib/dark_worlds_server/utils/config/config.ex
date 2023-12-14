defmodule Utils.Config do
  alias DarkWorldsServer.Config.Characters
  alias DarkWorldsServer.Config.Game

  def read_config_backend() do
    {:ok, json_config} = Application.app_dir(:dark_worlds_server, "priv/config.json") |> File.read()
    GameBackend.parse_config(json_config)
  end

  def delete_all_configs() do
    Characters.delete_all_characters()
    Characters.delete_all_skills()
    Characters.delete_all_effects()
    Characters.delete_all_character_skills()
    Characters.delete_all_projectiles()
    Game.delete_all_loot()
    Game.delete_all_loot_effects()
  end

  @doc """
  Reads characters, skills, character_skills, projectiles, effects and loots & stores them. Deletes preexisting records.

  Returns an {:ok, results} tuple where results is a map with :ok and :error keys, with integer values.
  """
  def clean_import_config() do
    delete_all_configs()

    %{effects: effects, skills: skills, characters: characters, projectiles: projectiles, loots: loots} =
      read_config_backend()

    effects_result = Enum.map(effects, &insert_effects/1)

    skills_result = Enum.map(skills, &Characters.insert_skill/1)

    characters_result = Enum.map(characters, &Characters.insert_character/1)

    character_skills_result = Enum.map(characters, &insert_character_skills/1) |> List.flatten()

    projectiles_result = Enum.map(projectiles, &Characters.insert_projectile/1)

    projectile_effects_result = Enum.map(projectiles, &insert_projectile_effects/1) |> List.flatten()

    loots_result = Enum.map(loots, &Game.insert_loot/1)

    loot_effects_result = Enum.map(loots, &insert_loot_effects/1) |> List.flatten()

    results =
      effects_result ++
        skills_result ++
        characters_result ++
        character_skills_result ++
        projectiles_result ++ projectile_effects_result ++ loots_result ++ loot_effects_result

    ok =
      Enum.count(results, fn
        {:ok, _} -> true
        {:error, _} -> false
        _other -> false
      end)

    {:ok, %{ok: ok, error: Enum.count(results) - ok}}
  end

  defp insert_effects(
         %{
           effect_time_type: effect_time_type,
           player_attributes: player_attributes,
           projectile_attributes: projectile_attributes
         } = effect
       ) do
    Characters.insert_effect(%{
      effect
      | effect_time_type: adapt_effect_time_type(effect_time_type),
        player_attributes: adapt_attribute_modifiers(player_attributes),
        projectile_attributes: adapt_attribute_modifiers(projectile_attributes)
    })
  end

  defp adapt_effect_time_type({_type, value_map}), do: value_map
  defp adapt_effect_time_type(value_map), do: value_map

  defp adapt_attribute_modifiers(attribute_modifiers),
    do: Enum.map(attribute_modifiers, &%{&1 | modifier: Atom.to_string(&1.modifier)})

  defp insert_character_skills(%{name: character_name, skills: skills}) do
    character_id = Characters.get_character_by_name(character_name).id

    Enum.map(skills, fn {skill_number, skill} ->
      skill_id = Characters.get_skill_by_name(skill.name).id
      Characters.insert_character_skill(%{character_id: character_id, skill_number: skill_number, skill_id: skill_id})
    end)
  end

  defp insert_projectile_effects(%{name: projectile_name, on_hit_effects: on_hit_effects}) do
    projectile_id = Characters.get_projectile_by_name(projectile_name).id

    Enum.map(on_hit_effects, fn effect ->
      effect_id = Characters.get_effect_by_name(effect.name).id
      Characters.insert_projectile_effect(%{projectile_id: projectile_id, effect_id: effect_id})
    end)
  end

  defp insert_loot_effects(%{name: loot_name, effects: effects}) do
    loot_id = Game.get_loot_by_name(loot_name).id

    Enum.map(effects, fn effect ->
      effect_id = Characters.get_effect_by_name(effect.name).id
      Game.insert_loot_effect(%{loot_id: loot_id, effect_id: effect_id})
    end)
  end
end
