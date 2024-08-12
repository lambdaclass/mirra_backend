defmodule Gateway.Controllers.CurseOfMirra.ConfigurationController do
  @moduledoc """
  Controller for Curse of Mirra Configurations
  """
  use Gateway, :controller
  alias GameBackend.Configuration

  action_fallback Gateway.Controllers.FallbackController

  def get_game_mode_configuration(conn, %{"game_mode" => game_mode}) do
    game_mode = Configuration.get_game_mode_by_name(game_mode) |> IO.inspect()
    version = Configuration.get_current_version_from_game_mode(game_mode)

    config =
      Jason.encode!(%{
        characters: encode_characters(version.characters),
        game: version.game_configuration,
        items: version.consumable_items,
        map: version.map_configurations
      })

    send_resp(conn, 200, config)
  end

  defp encode_characters(characters) when is_list(characters) do
    Enum.map(characters, fn character ->
      character
      |> Map.put(:basic_skill, encode_skill(character.basic_skill))
      |> Map.put(:ultimate_skill, encode_skill(character.ultimate_skill))
      |> Map.put(:dash_skill, encode_skill(character.dash_skill))
      |> ecto_struct_to_map()
    end)
  end

  defp encode_skill(nil) do
    nil
  end

  defp encode_skill(skill) do
    skill =
      GameBackend.Repo.preload(skill,
        next_skill: [mechanics: [:on_arrival_mechanic, :on_explode_mechanics, :parent_mechanic]]
      )

    skill
    |> Map.put(:next_skill, encode_skill(skill.next_skill))
    |> Map.put(:mechanics, encode_mechanics(skill.mechanics))
    |> ecto_struct_to_map()
    |> Map.drop([:buff])
  end

  defp encode_mechanics(mechanics) when is_list(mechanics) do
    Enum.map(mechanics, &encode_mechanic/1)
  end

  defp encode_mechanic(nil) do
    nil
  end

  defp encode_mechanic(mechanic) do
    # This is done to avoid the infinite nested mechanics loop
    # Once we enter on a mechanic, we don't want to go deeper (yet).
    on_explode_mechanics =
      Enum.map(mechanic.on_explode_mechanics, fn explode_mechanic ->
        explode_mechanic
        |> Map.put(:on_arrival_mechanic, nil)
        |> Map.put(:on_explode_mechanics, [])
        |> Map.put(:parent_mechanic, nil)
      end)

    on_arrival_mechanic =
      if mechanic.on_arrival_mechanic do
        mechanic.on_arrival_mechanic
        |> Map.put(:on_arrival_mechanic, nil)
        |> Map.put(:on_explode_mechanics, [])
        |> Map.put(:parent_mechanic, nil)
      else
        nil
      end

    mechanic
    |> Map.put(:on_arrival_mechanic, mechanic.on_arrival_mechanic_id && encode_mechanic(on_arrival_mechanic))
    |> Map.put(:on_explode_mechanics, encode_mechanics(on_explode_mechanics))
    |> ecto_struct_to_map()
    |> Map.drop([:skill, :apply_effects_to, :passive_effects])
  end

  defp ecto_struct_to_map(ecto_struct) when is_struct(ecto_struct) do
    ecto_struct
    |> Map.from_struct()
    |> Map.drop([
      :__meta__,
      :__struct__,
      :inserted_at,
      :updated_at,
      :id,
      :version
    ])
  end
end
