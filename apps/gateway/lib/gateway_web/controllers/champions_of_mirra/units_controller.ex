defmodule GatewayWeb.ChampionsOfMirra.UnitsController do
  @moduledoc """
  Controller for Champions Of Mirra requests involving units.

  No logic should be handled here. All logic should be handled through the ChampionsOfMirra app.
  """

  use GatewayWeb, :controller

  def select(conn, %{"user_id" => user_id, "unit_id" => unit_id, "slot" => slot}) do
    {slot, _rem} = Integer.parse(slot)

    ChampionsOfMirra.Units.select_unit(user_id, unit_id, slot)
    |> GatewayWeb.Utils.format_response(conn)
  end

  def unselect(conn, %{"user_id" => user_id, "unit_id" => unit_id}) do
    ChampionsOfMirra.Units.unselect_unit(user_id, unit_id)
    |> GatewayWeb.Utils.format_response(conn)
  end
end
