defmodule Gateway.Controllers.CurseOfMirra.ItemController do
  @moduledoc """
  Controller for Item modifications.
  """
  use Gateway, :controller
  alias GameBackend.Items
  alias GameBackend.Utils

  action_fallback Gateway.Controllers.FallbackController

  def equip(conn, params) do
    case Items.equip_item(params["user_id"], params["item_id"], params["unit_id"]) do
      {:ok, item} -> send_resp(conn, 200, Jason.encode!(item.id))
      error -> error
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
