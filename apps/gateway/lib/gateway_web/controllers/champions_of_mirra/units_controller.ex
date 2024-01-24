defmodule GatewayWeb.ChampionsOfMirra.UnitsController do
  use GatewayWeb, :controller

  def select(conn, %{"user_id" => user_id, "unit_id" => unit_id, "slot" => slot}) do
    case ChampionsOfMirra.process_units(:select_unit, user_id, unit_id, slot) do
      {:error, reason} ->
        conn
        |> put_status(400)
        |> json(reason)

      :ok ->
        json(conn, :ok)
    end
  end

  def unselect(conn, %{"unit_id" => unit_id}) do
    response = ChampionsOfMirra.process_units(:unselect_unit, unit_id)
    json(conn, response)
  end
end
