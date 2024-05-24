defmodule Gateway.Controllers.CurseOfMirra.ItemController do
  @moduledoc """
  Controller for Item modifications.
  """
  use Gateway, :controller
  alias GameBackend.Items
  alias GameBackend.Utils
  alias GameBackend.Units
  alias GameBackend.Users.Currencies

  action_fallback Gateway.Controllers.FallbackController

  def equip(conn, params) do
    with {:ok, unit} <- Units.get_unit_by_character_name(params["character_name"], params["user_id"]),
         {:ok, item} <- Items.get_item_by_name(params["item_name"], params["user_id"]),
         {:ok, :character_can_equip} <- Items.character_can_equip(unit, item),
         {:ok, item} <- Items.equip_item(params["user_id"], item.id, unit.id) do
      send_resp(conn, 200, Jason.encode!(item.id))
    end
  end

  # This is a placeholder and will be developed properly in https://github.com/lambdaclass/mirra_backend/issues/638
  def buy(conn, params) do
    with {:ok, item_template} <-
           Items.get_template_by_name_and_game_id(
             params["item_name"],
             Utils.get_game_id(:curse_of_mirra)
           ),
         {:ok, currency} <-
           Currencies.get_currency_by_name_and_game(params["currency_name"], Utils.get_game_id(:curse_of_mirra)),
         {:ok, purchase_cost} <- Items.get_item_template_purchase_cost_by_currency(item_template, currency.id),
         {:can_afford, true} <- {:can_afford, Currencies.can_afford(params["user_id"], [purchase_cost])},
         {:ok, item_updates_map} <- Items.buy_item(params["user_id"], item_template.id, [purchase_cost]) do
      send_resp(conn, 200, Jason.encode!(item_updates_map.item.id))
    end
  end
end
