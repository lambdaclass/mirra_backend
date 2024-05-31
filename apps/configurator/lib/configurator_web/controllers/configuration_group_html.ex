defmodule ConfiguratorWeb.ConfigurationGroupHTML do
  use ConfiguratorWeb, :html

  alias Configurator.Games.Game

  embed_templates "configuration_group_html/*"

  @doc """
  Renders a configuration form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :game, Game, required: true

  def configuration_group_form(assigns)
end
