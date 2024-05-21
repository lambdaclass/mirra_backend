defmodule Gateway.Controllers.CurseOfMirra.ItemController do
  @moduledoc """
  Controller for Item modifications.
  """
  use Gateway, :controller
  alias GameBackend.Items
  alias GameBackend.Utils
  alias GameBackend.Units

  action_fallback Gateway.Controllers.FallbackController

  def equip(conn, params) do
    with unit <- Units.get_unit_by_character_name(params["character_name"], params["user_id"]),
         item <- Items.get_item_by_name(params["item_name"], params["user_id"]),
         {:ok, item} <- Items.equip_item(params["user_id"], item.id, unit.id) do
      send_resp(conn, 200, Jason.encode!(item.id))
    end
  end

  # This is a placeholder and will be developed properly in https://github.com/lambdaclass/mirra_backend/issues/638
  def buy(conn, params) do
    with {:ok, item_template_id} <-
           Items.get_purchasable_template_id_by_name_and_game_id(
             params["item_name"],
             Utils.get_game_id(:curse_of_mirra)
           ),
         {:ok, item} <- Items.insert_item(%{user_id: params["user_id"], template_id: item_template_id}) do
      send_resp(conn, 200, Jason.encode!(item.id))
    end
  end
end
