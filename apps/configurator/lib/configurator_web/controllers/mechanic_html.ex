defmodule ConfiguratorWeb.MechanicHTML do
  use ConfiguratorWeb, :html

  embed_templates "mechanic_html/*"

  @doc """
  Renders a mechanic form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :mechanics, :list, required: true

  def mechanic_form(assigns)
end
