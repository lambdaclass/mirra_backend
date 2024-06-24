defmodule ConfiguratorWeb.GameConfigHTML do
  use ConfiguratorWeb, :html

  embed_templates "game_config_html/*"

  @doc """
  Renders a game_config form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def game_config_form(assigns)
end
