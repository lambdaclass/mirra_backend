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
    with {:ok, store} <- Stores.get_store_by_name_and_game(params["store_name"], Utils.get_game_id(:curse_of_mirra)) do
      send_resp(conn, 200, Jason.encode!(Stores.list_items_with_prices(store)))
    end
  end

  # TODO Add stock and amount check for store buyables and also
  # TODO allow to buy currencies. https://github.com/lambdaclass/mirra_backend/issues/661
  def buy_item(conn, params) do
    curse_of_mirra_id = Utils.get_game_id(:curse_of_mirra)

    with {:ok, store} <- Stores.get_store_by_name_and_game(params["store_name"], curse_of_mirra_id),
         {:ok, :active} <- Stores.is_active(store),
         {:ok, :item_in_store} <-
           Stores.item_in_store(params["item_name"], store.id, curse_of_mirra_id),
         {:ok, item_template} <-
           Items.get_template_by_name_and_game_id(
             params["item_name"],
             curse_of_mirra_id
           ),
         {:ok, currency} <-
           Currencies.get_currency_by_name_and_game(params["currency_name"], curse_of_mirra_id),
         {:ok, purchase_cost} <-
           Items.get_purchase_cost_by_currency(currency.id, item_template),
         {:can_afford, true} <- {:can_afford, Currencies.can_afford(params["user_id"], [purchase_cost])},
         {:ok, item_updates_map} <- Items.buy_item(params["user_id"], item_template.id, [purchase_cost]) do
      send_resp(conn, 200, Jason.encode!(item_updates_map.item.id))
    end
  end
end
