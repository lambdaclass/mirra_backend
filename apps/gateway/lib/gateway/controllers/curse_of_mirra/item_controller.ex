defmodule Gateway.Controllers.CurseOfMirra.ItemController do
  @moduledoc """
  Controller for Item modifications.
  """
  use Gateway, :controller
  alias GameBackend.Items
  alias GameBackend.Units

  action_fallback Gateway.Controllers.FallbackController

  def equip(conn, params) do
    with {:ok, unit} <- Units.get_unit_by_character_name(params["character_name"], params["user_id"]),
         {:ok, item} <- Items.get_item_by_name(params["item_name"], params["user_id"]),
         {:ok, :character_can_equip} <- Items.character_can_equip(unit, item),
         {:ok, item} <- Items.equip_item(params["user_id"], item.id, unit.id) do
      send_resp(conn, 200, Jason.encode!(item.id))
    end
  end
end
