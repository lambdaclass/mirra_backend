defmodule ConfiguratorWeb.ConsumableItemController do
  use ConfiguratorWeb, :controller

  alias GameBackend.Items
  alias GameBackend.Items.ConsumableItem

  def index(conn, _params) do
    consumable_items = Items.list_consumable_items()
    render(conn, :index, consumable_items: consumable_items)
  end

  def new(conn, _params) do
    changeset = Items.change_consumable_item(%ConsumableItem{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"consumable_item" => consumable_item_params}) do
    case Items.create_consumable_item(consumable_item_params) do
      {:ok, consumable_item} ->
        conn
        |> put_flash(:info, "Consumable item created successfully.")
        |> redirect(to: ~p"/consumable_items/#{consumable_item}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    consumable_item = Items.get_consumable_item!(id)
    render(conn, :show, consumable_item: consumable_item)
  end

  def edit(conn, %{"id" => id}) do
    consumable_item = Items.get_consumable_item!(id)
    changeset = Items.change_consumable_item(consumable_item)
    render(conn, :edit, consumable_item: consumable_item, changeset: changeset)
  end

  def update(conn, %{"id" => id, "consumable_item" => consumable_item_params}) do
    consumable_item = Items.get_consumable_item!(id)

    case Items.update_consumable_item(consumable_item, consumable_item_params) do
      {:ok, consumable_item} ->
        conn
        |> put_flash(:info, "Consumable item updated successfully.")
        |> redirect(to: ~p"/consumable_items/#{consumable_item}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, consumable_item: consumable_item, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    consumable_item = Items.get_consumable_item!(id)
    {:ok, _consumable_item} = Items.delete_consumable_item(consumable_item)

    conn
    |> put_flash(:info, "Consumable item deleted successfully.")
    |> redirect(to: ~p"/consumable_items")
  end
end
