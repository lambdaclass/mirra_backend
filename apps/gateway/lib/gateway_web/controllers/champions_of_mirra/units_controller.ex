defmodule GatewayWeb.ChampionsOfMirra.UnitsController do
  @moduledoc """
  Controller for Champions Of Mirra requests involving units.

  No logic should be handled here. All logic should be handled through the ChampionsOfMirra app.
  """

  use GatewayWeb, :controller

  def select(conn, %{"user_id" => user_id, "unit_id" => unit_id, "slot" => slot}) do
    {slot, _rem} = Integer.parse(slot)

    case ChampionsOfMirra.Units.select_unit(user_id, unit_id, slot) do
      {:error, reason} ->
        conn
        |> put_status(400)
        |> json(reason)

      unit ->
        json(conn, unit)
    end
  end

  def unselect(conn, %{"user_id" => user_id, "unit_id" => unit_id}) do
    response = ChampionsOfMirra.Units.unselect_unit(user_id, unit_id)
    json(conn, response)
  end
end
