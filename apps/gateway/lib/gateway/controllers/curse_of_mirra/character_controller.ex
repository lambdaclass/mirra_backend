defmodule Gateway.Controllers.CurseOfMirra.CharacterController do
  @moduledoc """
  Controller for Character modifications.
  """
  use Gateway, :controller
  # alias GameBackend.Items
  alias GameBackend.Units

  action_fallback Gateway.Controllers.FallbackController

  def select(conn, params) do
    with {:ok, units} <- Units.list_units_by_user(params["user_id"]),
        {:ok, _transaction} <- Units.select_unit_character(units, params["character_name"]) do
      send_resp(conn, 200, Jason.encode!(%{character_name: params["character_name"]}))
    end
  end

  def select_skin(conn, params) do
    with {:ok, unit} <- Units.get_unit_by_character_name(params["character_name"], params["user_id"]),
        {:ok, :skin_exists} <- Units.has_skin?(unit, params["skin_name"]),
        {:ok, transaction} <- Units.select_unit_skin(unit, params["skin_name"]) do
      IO.inspect(transaction)
      send_resp(conn, 200, Jason.encode!(%{character_name: params["character_name"], skin_name: params["skin_name"]}))
    end
  end
end
