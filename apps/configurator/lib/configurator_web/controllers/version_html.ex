defmodule ConfiguratorWeb.VersionHTML do
  use ConfiguratorWeb, :html
  import ConfiguratorWeb.SkillHTML
  import ConfiguratorWeb.MapConfigurationHTML

  embed_templates "version_html/*"

  @doc """
  Renders a version form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :last_version, GameBackend.Configuration.Version
  attr :skills, :list

  def version_form(assigns)

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
