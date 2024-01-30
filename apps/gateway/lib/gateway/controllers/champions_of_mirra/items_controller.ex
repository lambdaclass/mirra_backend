defmodule Gateway.ChampionsOfMirra.ItemsController do
  @moduledoc """
  Controller for Champions Of Mirra requests involving items.

  No logic should be handled here. All logic should be handled through the ChampionsOfMirra app.
  """

  use Gateway, :controller

  def equip_item(conn, %{"user_id" => user_id, "item_id" => item_id, "unit_id" => unit_id}) do
    ChampionsOfMirra.Items.equip_item(user_id, item_id, unit_id)
    |> Gateway.Utils.format_response(conn)
  end

  def unequip_item(conn, %{"user_id" => user_id, "item_id" => item_id}) do
    ChampionsOfMirra.Items.unequip_item(user_id, item_id)
    |> Gateway.Utils.format_response(conn)
  end

  def get_item(conn, %{"item_id" => item_id}) do
    ChampionsOfMirra.Items.get_item(item_id) |> Gateway.Utils.format_response(conn)
  end

  def level_up(conn, %{"user_id" => user_id, "item_id" => item_id}) do
    ChampionsOfMirra.Items.level_up(user_id, item_id) |> Gateway.Utils.format_response(conn)
  end
end
