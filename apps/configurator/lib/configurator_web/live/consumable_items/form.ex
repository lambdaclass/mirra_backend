defmodule ConfiguratorWeb.ConsumableItemsLive.Form do
  use ConfiguratorWeb, :live_view

  alias GameBackend.Items
  alias GameBackend.Items.ConsumableItem
  alias GameBackend.Configuration

  def mount(
        _params,
        %{"consumable_item" => consumable_item, "version" => version},
        socket
      ) do
    changeset = Items.change_consumable_item(consumable_item)

    socket =
      assign(socket, changeset: changeset, action: "update", consumable_item: consumable_item, version: version)

    {:ok, socket}
  end

  def mount(
        _params,
        %{"version" => version},
        socket
      ) do
    changeset = Items.change_consumable_item(%ConsumableItem{})
    socket = assign(socket, changeset: changeset, action: "save", version: version, consumable_item: %{})
    {:ok, socket}
  end

  def handle_event("validate", %{"consumable_item" => consumable_item_params}, socket) do
    changeset = socket.assigns.changeset
    changeset = ConsumableItem.changeset(changeset, consumable_item_params)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"consumable_item" => consumable_item_params}, socket) do
    socket =
      case Items.create_consumable_item(consumable_item_params) do
        {:ok, consumable_item} ->
          socket
          |> put_flash(:info, "Consumable item created successfully.")
          |> redirect(to: ~p"/versions/#{consumable_item.version_id}/consumable_items/#{consumable_item.id}")

        {:error, %Ecto.Changeset{} = changeset} ->
          version = Configuration.get_version!(consumable_item_params["version_id"])

          socket
          |> put_flash(:error, "Please correct the errors below.")
          |> assign(changeset: changeset, version: version)
      end

    {:noreply, socket}
  end

  def handle_event("update", %{"consumable_item" => consumable_item_params}, socket) do
    consumable_item = socket.assigns.consumable_item

    socket =
      case Items.update_consumable_item(consumable_item, consumable_item_params) do
        {:ok, consumable_item} ->
          socket
          |> put_flash(:info, "Consumable item updated successfully.")
          |> redirect(to: ~p"/versions/#{consumable_item.version_id}/consumable_items/#{consumable_item.id}")

        {:error, %Ecto.Changeset{} = changeset} ->
          version = Configuration.get_version!(consumable_item.version_id)

          socket
          |> put_flash(:error, "Please correct the errors below.")
          |> assign(changeset: changeset, version: version)
      end

    {:noreply, socket}
  end
end
