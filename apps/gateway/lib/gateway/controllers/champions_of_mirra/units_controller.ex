defmodule Gateway.Champions.UnitsController do
  @moduledoc """
  Controller for Champions Of Mirra requests involving units.

  No logic should be handled here. All logic should be handled through the Champions app.
  """

  use Gateway, :controller

  def select(conn, %{"user_id" => user_id, "unit_id" => unit_id, "slot" => slot}) do
    {slot, _rem} = Integer.parse(slot)

    Champions.Units.select_unit(user_id, unit_id, slot)
    |> Gateway.Utils.format_response(conn)
  end

  def unselect(conn, %{"user_id" => user_id, "unit_id" => unit_id}) do
    Champions.Units.unselect_unit(user_id, unit_id)
    |> Gateway.Utils.format_response(conn)
  end
end
