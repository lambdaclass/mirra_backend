defmodule ConfiguratorWeb.GameModeConfigurationHTML do
  use ConfiguratorWeb, :html

  embed_templates "game_mode_configuration_html/*"

  @doc """
  Renders a game_mode_configuration form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :version, GameBackend.Configuration.Version, required: true

  def game_mode_configuration_form(assigns)
end
