defmodule GatewayWeb.ChampionsOfMirra.ItemsController do
  use GatewayWeb, :controller

  def get_item(conn, %{"item_id" => item_id}) do
    case ChampionsOfMirra.process_items(:get_item, item_id) do
      {:error, reason} ->
        conn
        |> put_status(400)
        |> json(reason)

      {:ok, item} ->
        json(conn, item)
    end
  end

  def level_up(conn, %{"item_id" => item_id}) do
    response = ChampionsOfMirra.process_items(:level_up, item_id)
    json(conn, response)
  end
end
