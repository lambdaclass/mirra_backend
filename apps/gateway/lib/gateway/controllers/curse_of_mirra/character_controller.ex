defmodule Gateway.Controllers.CurseOfMirra.CharacterController do
  @moduledoc """
  Controller for Character modifications.
  """
  use Gateway, :controller

  action_fallback Gateway.Controllers.FallbackController

  def get_characters_config(conn, _params) do
    case GameBackend.Units.Characters.get_curse_characters() do
      [] -> {:error, :not_found}
      characters -> send_resp(conn, 200, Jason.encode!(encode_characters(characters)))
    end
  end

  defp ecto_struct_to_map(ecto_struct) when is_struct(ecto_struct) do
    ecto_struct
    |> Map.from_struct()
    |> Map.drop([
      :__meta__,
      :__struct__,
      :inserted_at,
      :updated_at,
      :id
    ])
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

  defp encode_skill(skill) do
    skill
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
    mechanic
    |> Map.put(:on_arrival_mechanic, mechanic.on_arrival_mechanic_id && encode_mechanic(mechanic.on_arrival_mechanic))
    |> Map.put(:on_explode_mechanic, mechanic.on_explode_mechanic_id && encode_mechanic(mechanic.on_explode_mechanic))
    |> ecto_struct_to_map()
    |> Map.drop([:skill, :apply_effects_to, :passive_effects])
  end
end
