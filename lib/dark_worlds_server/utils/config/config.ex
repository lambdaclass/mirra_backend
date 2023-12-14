defmodule Utils.Config do
  alias DarkWorldsServer.Characters

  def read_config_backend() do
    {:ok, json_config} = Application.app_dir(:dark_worlds_server, "priv/config.json") |> File.read()
    GameBackend.parse_config(json_config)
  end

  @doc """
  Reads characters, skills, character_skills and effects & stores them. Deletes preexisting records.

  Returns an {:ok, results} tuple where results is a map with :ok and :error keys, with integer values.
  """
  def clean_import_config() do
    Characters.delete_all()
    %{effects: effects, skills: skills, characters: characters} = read_config_backend()

    effects_result =
      Enum.map(
        effects,
        &(&1 |> adapt_effects_map() |> Characters.insert_effect())
      )

    skills_result = Enum.map(skills, &Characters.insert_skill(&1))

    characters_result = Enum.map(characters, &Characters.insert_character(&1))

    character_skills_result = Enum.map(characters, &insert_character_skills(&1)) |> List.flatten()

    results = effects_result ++ skills_result ++ characters_result ++ character_skills_result

    ok =
      Enum.count(results, fn
        {:ok, _} -> true
        {:error, _} -> false
        _other -> false
      end)

    {:ok, %{ok: ok, error: Enum.count(results) - ok}}
  end

  defp adapt_effects_map(
         %{
           effect_time_type: effect_time_type,
           player_attributes: player_attributes,
           projectile_attributes: projectile_attributes
         } = effect
       ),
       do: %{
         effect
         | effect_time_type: adapt_effect_time_type(effect_time_type),
           player_attributes: adapt_attribute_modifiers(player_attributes),
           projectile_attributes: adapt_attribute_modifiers(projectile_attributes)
       }

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
end
