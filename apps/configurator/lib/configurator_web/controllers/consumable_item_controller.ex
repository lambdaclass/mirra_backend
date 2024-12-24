defmodule ConfiguratorWeb.ConsumableItemController do
  use ConfiguratorWeb, :controller

  alias GameBackend.Items
  alias GameBackend.Items.ConsumableItem
  alias GameBackend.Configuration

  def index(conn, %{"version_id" => version_id}) do
    consumable_items = Items.list_consumable_items_by_version(version_id)
    render(conn, :index, consumable_items: consumable_items, version_id: version_id)
  end

  def new(conn, %{"version_id" => version_id}) do
    changeset = Items.change_consumable_item(%ConsumableItem{})
    version = Configuration.get_version!(version_id)
    render(conn, :new, changeset: changeset, version: version)
  end

  def create(conn, %{"consumable_item" => consumable_item_params}) do
    case Items.create_consumable_item(consumable_item_params) do
      {:ok, consumable_item} ->
        conn
        |> put_flash(:info, "Consumable item created successfully.")
        |> redirect(to: ~p"/versions/#{consumable_item_params.version_id}/consumable_items/#{consumable_item}")

      {:error, %Ecto.Changeset{} = changeset} ->
        version = Configuration.get_version!(consumable_item_params["version_id"])
        render(conn, :new, changeset: changeset, version: version)
    end
  end

  def show(conn, %{"id" => id}) do
    consumable_item = Items.get_consumable_item!(id)
    version = Configuration.get_version!(consumable_item.version_id)
    render(conn, :show, consumable_item: consumable_item, version: version)
  end

  def edit(conn, %{"id" => id}) do
    consumable_item = Items.get_consumable_item!(id)
    changeset = Items.change_consumable_item(consumable_item)
    version = Configuration.get_version!(consumable_item.version_id)
    render(conn, :edit, consumable_item: consumable_item, changeset: changeset, version: version)
  end

  def update(conn, %{"id" => id, "consumable_item" => consumable_item_params}) do
    consumable_item = Items.get_consumable_item!(id)

    case Items.update_consumable_item(consumable_item, consumable_item_params) do
      {:ok, consumable_item} ->
        conn
        |> put_flash(:info, "Consumable item updated successfully.")
        |> redirect(to: ~p"/versions/#{consumable_item_params.version_id}/consumable_items/#{consumable_item}")

      {:error, %Ecto.Changeset{} = changeset} ->
        version = Configuration.get_version!(consumable_item.version_id)
        render(conn, :edit, consumable_item: consumable_item, changeset: changeset, version: version)
    end
  end

  def delete(conn, %{"id" => id}) do
    consumable_item = Items.get_consumable_item!(id)
    version_id = consumable_item.version_id
    {:ok, _consumable_item} = Items.delete_consumable_item(consumable_item)

    conn
    |> put_flash(:info, "Consumable item deleted successfully.")
    |> redirect(to: ~p"/versions/#{version_id}/consumable_items")
  end
end
