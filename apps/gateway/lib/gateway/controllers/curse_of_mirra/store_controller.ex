defmodule Gateway.Controllers.CurseOfMirra.StoreController do
  @moduledoc """
  Controller for Item modifications.
  """
  use Gateway, :controller
  alias GameBackend.Items
  alias GameBackend.Utils
  alias GameBackend.Users.Currencies
  alias GameBackend.Stores
  alias GameBackend.Units
  alias GameBackend.Units.Characters

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
         {:ok, :active} <- Stores.store_is_active(store),
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
           Items.get_item_template_purchase_cost_by_currency(item_template, currency.id),
         {:can_afford, true} <- {:can_afford, Currencies.can_afford(params["user_id"], [purchase_cost])},
         {:ok, item_updates_map} <- Items.buy_item(params["user_id"], item_template.id, [purchase_cost]) do
      send_resp(conn, 200, Jason.encode!(%{item_id: item_updates_map.item.id}))
    end
  end

  def list_skins(conn, _params) do
    with {:ok, skins} <- Characters.list_skins_with_prices() do
      send_resp(conn, 200, Jason.encode!(%{skins: skins}))
    end
  end

  def buy_skin(conn, params) do
    curse_of_mirra_id = GameBackend.Utils.get_game_id(:curse_of_mirra)

    with {:ok, skin} <- Characters.get_skin_by_name(params["skin_name"]),
         {:ok, unit} <- Units.get_unit_by_character_id(params["user_id"], skin.character_id),
         {:already_bought_skin?, false} <- {:already_bought_skin?, Units.has_skin?(unit, params["skin_name"])},
         {:ok, currency} <-
           Currencies.get_currency_by_name_and_game(params["currency_name"], curse_of_mirra_id),
         {:ok, purchase_cost} <-
           Characters.get_skin_purchase_cost_by_currency(skin, currency.id),
         {:can_afford, true} <- {:can_afford, Currencies.can_afford(params["user_id"], [purchase_cost])},
         {:ok, %{updated_user: updated_user}} <-
           Characters.buy_skin(%{user_id: params["user_id"], skin_id: skin.id, unit_id: unit.id}, [purchase_cost]) do
      send_resp(conn, 200, Jason.encode!(updated_user))
    end
  end
end
