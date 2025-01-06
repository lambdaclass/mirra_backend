defmodule ConfiguratorWeb.VersionHTML do
  use ConfiguratorWeb, :html
  import ConfiguratorWeb.SkillHTML
  import ConfiguratorWeb.MapConfigurationHTML
  import ConfiguratorWeb.CharacterHTML

  embed_templates "version_html/*"

  @doc """
  Renders a version form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :last_version, GameBackend.Configuration.Version
  attr :skills, :list

  def version_form(assigns)
end
