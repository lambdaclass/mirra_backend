defmodule ConfiguratorWeb.GameModeHTML do
  use ConfiguratorWeb, :html

  embed_templates "game_mode_html/*"

  @doc """
  Renders a game_mode form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def game_mode_form(assigns)
end
