defmodule ConfiguratorWeb.ConsumableItemHTML do
  use ConfiguratorWeb, :html

  embed_templates "consumable_item_html/*"

  def display_effect(assigns) do
    ~H"""
    <.modal id={@consumable_item.name}>
      <.table id="effects" rows={@consumable_item.effects}>
        <:col :let={effect} label="Name"><%= effect.name %></:col>
        <:col :let={effect} label="Remove on Action"><%= effect.remove_on_action %></:col>
        <:col :let={effect} label="Duration ms"><%= effect.duration_ms %></:col>
        <:col :let={effect} label="One Time Application"><%= effect.one_time_application %></:col>
        <:col :let={effect} label="Mechanics"><%= Jason.encode!(effect.mechanics) %></:col>
      </.table>
    </.modal>
    <.button class="" phx-click={show_modal(@consumable_item.name)}>Effects</.button>
    """
  end
end
