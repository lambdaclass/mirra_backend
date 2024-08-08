defmodule ConfiguratorWeb.ArenaServerHTML do
  use ConfiguratorWeb, :html

  embed_templates "arena_server_html/*"

  @doc """
  Renders a arena_server form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def arena_server_form(assigns)
end
