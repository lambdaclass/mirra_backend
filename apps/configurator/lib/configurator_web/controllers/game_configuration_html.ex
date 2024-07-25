defmodule ConfiguratorWeb.GameConfigurationHTML do
  use ConfiguratorWeb, :html

  embed_templates "game_configuration_html/*"

  @doc """
  Renders a game_configuration form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def game_configuration_form(assigns)
end
