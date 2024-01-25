defmodule GatewayWeb.ChampionsOfMirra.ItemsController do
  use GatewayWeb, :controller

  def equip_item(conn, %{"user_id" => user_id, "item_id" => item_id, "unit_id" => unit_id}) do
    case ChampionsOfMirra.process_items(:equip_item, user_id, item_id, unit_id) do
      {:error, reason} ->
        conn
        |> put_status(400)
        |> json(reason)

      {:ok, item} ->
        json(conn, item)
    end
  end

  def unequip_item(conn, %{"user_id" => user_id, "item_id" => item_id}) do
    case ChampionsOfMirra.process_items(:unequip_item, user_id, item_id) do
      {:error, reason} ->
        conn
        |> put_status(400)
        |> json(reason)

      {:ok, item} ->
        json(conn, item)
    end
  end

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

  def level_up(conn, %{"user_id" => user_id, "item_id" => item_id}) do
    response = ChampionsOfMirra.process_items(:level_up, user_id, item_id)
    json(conn, response)
  end
end
