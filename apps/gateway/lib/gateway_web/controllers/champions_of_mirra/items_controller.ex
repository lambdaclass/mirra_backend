defmodule GatewayWeb.ChampionsOfMirra.ItemsController do
  @moduledoc """
  Controller for Champions Of Mirra requests involving items.

  No logic should be handled here. All logic should be handled through the ChampionsOfMirra app.
  """

  use GatewayWeb, :controller

  def equip_item(conn, %{"user_id" => user_id, "item_id" => item_id, "unit_id" => unit_id}) do
    case ChampionsOfMirra.Units.equip_item(user_id, item_id, unit_id) do
      {:error, reason} ->
        conn
        |> put_status(400)
        |> json(reason)

      {:ok, item} ->
        json(conn, item)
    end
  end

  def unequip_item(conn, %{"user_id" => user_id, "item_id" => item_id}) do
    case ChampionsOfMirra.Units.unequip_item(user_id, item_id) do
      {:error, reason} ->
        conn
        |> put_status(400)
        |> json(reason)

      {:ok, item} ->
        json(conn, item)
    end
  end

  def get_item(conn, %{"item_id" => item_id}) do
    case ChampionsOfMirra.Items.get_item(item_id) do
      {:error, reason} ->
        conn
        |> put_status(400)
        |> json(reason)

      {:ok, item} ->
        json(conn, item)
    end
  end

  def level_up(conn, %{"user_id" => user_id, "item_id" => item_id}) do
    case ChampionsOfMirra.Items.level_up(user_id, item_id) do
      {:error, reason} ->
        conn
        |> put_status(400)
        |> json(reason)

      {:ok, item} ->
        json(conn, item)
    end
  end
end
