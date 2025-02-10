defmodule Gateway.Controllers.CurseOfMirra.CharacterController do
  @moduledoc """
  Controller for Character modifications.
  """
  use Gateway, :controller
  # alias GameBackend.Items
  alias GameBackend.Units

  action_fallback Gateway.Controllers.FallbackController

  def select(conn, params) do
    with {:ok, unit} <- Units.get_unit_by_character_name(params["character_name"], params["user_id"]),
         :ok <- Units.select_character_and_skin(unit, params["skin_name"]) do
        #  {:ok, item} <- Items.get_item_by_name(params["item_name"], params["user_id"]),
        #  {:ok, :character_can_equip} <- Items.character_can_equip(unit, item),
        #  {:ok, item} <- Items.equip_item(params["user_id"], item.id, unit.id) do
      send_resp(conn, 200, Jason.encode!(%{character_name: unit.character, skin_name: params["skin_name"]}))
    end
  end
end
