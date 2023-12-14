defmodule Utils.Config do
  alias DarkWorldsServer.Characters

  def read_config_backend() do
    {:ok, json_config} = Application.app_dir(:dark_worlds_server, "priv/config.json") |> File.read()
    GameBackend.parse_config(json_config)
  end

  @doc """
  Reads characters, skills, character_skills and effects & stores them.
  """
  def clean_import_config() do
    Characters.delete_all()
    %{effects: effects, skills: skills, characters: characters} = read_config_backend()

    _effects_result =
      Enum.map(
        effects,
        &(&1 |> adapt_effects_map() |> Characters.insert_effect())
      )

    _skills_result = Enum.map(skills, &Characters.insert_skill(&1))

    _characters_result = Enum.map(characters, &Characters.insert_character(&1))

    _character_skills_result = Enum.map(characters, &(&1 |> insert_character_skills()))
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
