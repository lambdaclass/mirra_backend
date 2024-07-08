defmodule ConfiguratorWeb.MapConfigurationHTML do
  use ConfiguratorWeb, :html

  embed_templates "map_configuration_html/*"

  @doc """
  Renders a map_configuration form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def map_configuration_form(assigns)
end
