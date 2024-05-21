defmodule Gateway.Controllers.CurseOfMirra.ItemController do
  @moduledoc """
  Controller for User modifications.
  """
  use Gateway, :controller
  alias GameBackend.Items

  action_fallback Gateway.Controllers.FallbackController

  def equip(conn, params) do
    case Items.equip_item(params["user_id"], params["item_id"], params["unit_id"]) do
      {:ok, item} -> send_resp(conn, 200, Jason.encode!(item.id))
      error -> error
    end
  end
end
