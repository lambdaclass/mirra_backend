defmodule ConfiguratorWeb.ConfigurationHTML do
  use ConfiguratorWeb, :html

  alias Configurator.Games.Game
  alias Configurator.Configure.ConfigurationGroup

  embed_templates "configuration_html/*"

  @doc """
  Renders a configuration form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :game, Game, required: true
  attr :configuration_group, ConfigurationGroup, required: true
  def configuration_form(assigns)
end
