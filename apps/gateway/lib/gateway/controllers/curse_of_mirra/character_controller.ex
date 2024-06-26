defmodule Gateway.Controllers.CurseOfMirra.CharacterController do
  @moduledoc """
  Controller for Character modifications.
  """
  use Gateway, :controller

  action_fallback Gateway.Controllers.FallbackController

  def get_characters_config(conn, _params) do
    case GameBackend.Units.Characters.get_curse_characters() do
      [] -> {:error, :not_found}
      characters -> send_resp(conn, 200, Jason.encode!(transform_to_map_from_ecto_struct(characters)))
    end
  end

  defp transform_to_map_from_ecto_struct(ecto_struct) when is_struct(ecto_struct) do
    ecto_struct
    |> Map.from_struct()
    |> Map.drop([
      :__meta__,
      :__struct__,
      :inserted_at,
      :updated_at,
      :id,
      :basic_skill,
      :ultimate_skill
    ])
  end

  defp transform_to_map_from_ecto_struct(ecto_structs) when is_list(ecto_structs) do
    Enum.map(ecto_structs, fn ecto_struct ->
      transform_to_map_from_ecto_struct(ecto_struct)
    end)
  end
end
