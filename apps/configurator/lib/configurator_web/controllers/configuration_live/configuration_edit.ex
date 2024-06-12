defmodule ConfiguratorWeb.ConfigurationLive.ConfigurationEdit do
  import ConfiguratorWeb.ConfigurationHTML
  use ConfiguratorWeb, :html
  use Phoenix.LiveView
  use Phoenix.Component

  def render do
    render("configuration_edit.html")
  end

  def mount(
        _params,
        %{
          "game" => game,
          "configuration_group" => configuration_group,
          "configuration" => configuration
        },
        socket
      ) do
    data = Jason.decode!(configuration.data)

    socket =
      socket
      |> assign(:game, game)
      |> assign(:configuration_group, configuration_group)
      |> assign(:configuration, configuration)
      |> assign(:data, data)

    {:ok, socket}
  end
end
