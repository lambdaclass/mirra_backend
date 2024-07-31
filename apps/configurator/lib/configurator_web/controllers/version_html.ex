defmodule ConfiguratorWeb.VersionHTML do
  use ConfiguratorWeb, :html
  alias GameBackend.Configuration

  embed_templates "version_html/*"

  @doc """
  Renders a version form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def version_form(assigns)
end
