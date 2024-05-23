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
    with {:ok, item_template_id} <-
           Items.get_purchasable_template_id_by_name_and_game_id(
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
