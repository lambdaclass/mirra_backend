defmodule ConfiguratorWeb.ConsumableItemHTML do
  use ConfiguratorWeb, :html

  embed_templates "consumable_item_html/*"

  @doc """
  Renders a consumable_item form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def consumable_item_form(assigns)

  def display_effect(assigns) do
    ~H"""
    <.modal id={@consumable_item.name}>
      <.table id="effects" rows={@consumable_item.effects}>
        <:col :let={effect} label="Name"><%= effect.name %></:col>
        <:col :let={effect} label="Remove on Action"><%= effect.remove_on_action %></:col>
        <:col :let={effect} label="Duration ms"><%= effect.duration_ms %></:col>
        <:col :let={effect} label="One Time Application"><%= effect.one_time_application %></:col>
      </.table>
    </.modal>
    <.button class="" phx-click={show_modal(@consumable_item.name)}>Effects</.button>
    """
  end
end
