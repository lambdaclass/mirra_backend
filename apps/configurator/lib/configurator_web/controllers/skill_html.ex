defmodule ConfiguratorWeb.SkillHTML do
  use ConfiguratorWeb, :html
  alias GameBackend.Units.Skills.Mechanic

  embed_templates "skill_html/*"

  @doc """
  Renders a skill form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def skill_form(assigns)

  @doc """
  Renders the inputs for a mechanic inside a skill form.
  """
  attr :skill_form, Phoenix.HTML.FormField, required: true

  def skill_mechanic_inputs(assigns)

  @doc """
  Renders the inputs for a nested mechanic inside skill_mechanic_inputs/1.
  """
  attr :parent_form, Phoenix.HTML.FormField, required: true
  attr :parent_field, :atom, required: true

  def nested_mechanic_inputs(assigns)

  @doc """
  Renders to show a mechanic.
  """
  attr :mechanic, Mechanic, required: true

  def mechanic_show(assigns)
end
