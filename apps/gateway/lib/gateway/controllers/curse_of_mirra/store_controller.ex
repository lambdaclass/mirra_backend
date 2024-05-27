defmodule Gateway.Controllers.CurseOfMirra.StoreController do
  @moduledoc """
  Controller for Item modifications.
  """
  use Gateway, :controller
  alias GameBackend.Items
  alias GameBackend.Utils
  alias GameBackend.Users.Currencies
  alias GameBackend.Stores

  action_fallback Gateway.Controllers.FallbackController

  def list_items(conn, params) do
    with {:ok, store} <- Stores.get_store_by_name(params["store_name"]),
         {:ok, items_with_prices} <- Stores.list_items_with_prices(store) do
      send_resp(conn, 200, Jason.encode!(items_with_prices))
    end
  end

  def buy_item(conn, params) do
    with {:ok, store} <- Stores.get_store_by_name(params["store_name"]),
         {:ok, :item_in_store} <- Stores.item_in_store(params["item_name"], store),
         {:ok, :active} <- Stores.is_active(store),
         {:ok, item_template_id} <-
           Items.get_template_id_by_name_and_game_id(
             params["item_name"],
             Utils.get_game_id(:curse_of_mirra)
           ),
         {:ok, item_cost} <-
           Items.get_item_cost_by_name(params["cost_name"], item_template_id),
         {:can_afford, true} <- {:can_afford, Currencies.can_afford(params["user_id"], item_cost.currency_costs)},
         {:ok, item_updates_map} <- Items.buy_item(params["user_id"], item_template_id, item_cost.currency_costs) do
      send_resp(conn, 200, Jason.encode!(item_updates_map.item.id))
    end
  end
end
