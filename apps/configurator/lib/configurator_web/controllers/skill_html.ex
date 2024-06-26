defmodule ConfiguratorWeb.SkillHTML do
  use ConfiguratorWeb, :html

  embed_templates "skill_html/*"

  @doc """
  Renders a skill form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def skill_form(assigns)
end
