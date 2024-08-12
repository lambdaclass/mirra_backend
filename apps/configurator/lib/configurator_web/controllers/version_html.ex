defmodule ConfiguratorWeb.VersionHTML do
  use ConfiguratorWeb, :html

  embed_templates "version_html/*"

  @doc """
  Renders a version form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :game_modes, :list

  def version_form(assigns)
end
