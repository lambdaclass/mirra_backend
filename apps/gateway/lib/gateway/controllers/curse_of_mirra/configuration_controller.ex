defmodule Gateway.Controllers.CurseOfMirra.ConfigurationController do
  @moduledoc """
  Controller for Curse of Mirra Configurations
  """
  use Gateway, :controller
  alias GameBackend.CurseOfMirra.Config
  alias GameBackend.Configuration

  action_fallback Gateway.Controllers.FallbackController

  def get_characters_configuration(conn, _params) do
    case Config.get_characters_config() do
      nil -> {:error, :not_found}
      characters_config -> send_resp(conn, 200, Jason.encode!(characters_config))
    end
  end

  def get_game_configuration(conn, _params) do
    game_configuration = Configuration.get_latest_game_configuration() |> transform_to_map_from_ecto_struct()
    send_resp(conn, 200, Jason.encode!(game_configuration))
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
