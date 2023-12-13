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
    config = read_config_backend()
    effects = config.effects

    _effects_result =
      Enum.map(
        effects,
        &(&1 |> adapt_effect_map() |> Map.drop([:skills_keys_to_execute]) |> Characters.insert_effect())
      )

    # _effect_skills = Enum.map(effects, &(&1.skills_keys_to_execute))
  end

  defp adapt_effect_map(
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
end
