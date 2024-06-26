defmodule ConfiguratorWeb.SkillHTML do
  use ConfiguratorWeb, :html

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
end
