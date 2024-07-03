defmodule ConfiguratorWeb.CharacterHTML do
  use ConfiguratorWeb, :html

  embed_templates "character_html/*"

  @doc """
  Renders a character form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :skills, :list, required: true

  def character_form(assigns)

  attr :field, Phoenix.HTML.FormField, required: true
  attr :label, :string, required: true
  attr :skills, :list, required: true

  def skill_select(assigns) do
    ~H"""
    <.input
      field={@field}
      type="select"
      label={@label}
      prompt="Select a skill"
      options={Enum.map(@skills, &{&1.name, &1.id})}
    />
    """
  end
end
