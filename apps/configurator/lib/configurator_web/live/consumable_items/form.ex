defmodule ConfiguratorWeb.ConsumableItemsLive.Form do
  use ConfiguratorWeb, :live_view

  alias GameBackend.Items
  alias GameBackend.Items.ConsumableItem
  alias GameBackend.Effects.ConfigurationEffect

  def mount(
        _params,
        %{"consumable_item" => consumable_item},
        socket
      ) do
    changeset = Items.change_consumable_item(consumable_item) |> IO.inspect()

    socket =
      socket |> assign(:changeset, changeset) |> assign(:action, "update") |> assign(:consumable_item, consumable_item)

    {:ok, socket}
  end

  def mount(
        _params,
        _session,
        socket
      ) do
    changeset = Items.change_consumable_item(%ConsumableItem{})
    socket = socket |> assign(:changeset, changeset) |> assign(:action, "save")
    {:ok, socket}
  end

  def handle_event("validate", %{"consumable_item" => consumable_item_params}, socket) do
    changeset = socket.assigns.changeset
    changeset = ConsumableItem.changeset(changeset, consumable_item_params)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("add_effect", _params, socket) do
    changeset = socket.assigns.changeset
    effects = Ecto.Changeset.get_field(changeset, :effects) || []
    new_effect = %ConfigurationEffect{}
    changeset = Ecto.Changeset.put_assoc(changeset, :effects, [new_effect | effects])

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"consumable_item" => consumable_item_params}, socket) do
    socket =
      case Items.create_consumable_item(consumable_item_params) |> IO.inspect() do
        {:ok, consumable_item} ->
          socket
          |> put_flash(:info, "Consumable item created successfully.")
          |> redirect(to: ~p"/consumable_items/#{consumable_item.id}")

        {:error, %Ecto.Changeset{} = changeset} ->
          socket
          |> put_flash(:error, "Please correct the errors below.")
          |> assign(:changeset, changeset)
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
          |> redirect(to: ~p"/consumable_items/#{consumable_item.id}")

        {:error, %Ecto.Changeset{} = changeset} ->
          socket
          |> put_flash(:error, "Please correct the errors below.")
          |> assign(:changeset, changeset)
      end

    {:noreply, socket}
  end
end