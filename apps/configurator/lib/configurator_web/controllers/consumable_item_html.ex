defmodule ConfiguratorWeb.ConsumableItemHTML do
  use ConfiguratorWeb, :html

  embed_templates "consumable_item_html/*"

  @doc """
  Renders a consumable_item form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def consumable_item_form(assigns)
end
