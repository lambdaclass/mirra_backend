defmodule ConfiguratorWeb.ConfigurationLive.ConfigurationShow do
  use ConfiguratorWeb, :html
  use Phoenix.LiveView
  use Phoenix.Component

  def render do
    render("configuration_how.html")
  end

  def mount(
        _params,
        %{"game" => game, "configuration_group" => configuration_group, "configuration" => configuration},
        socket
      ) do
    data = Jason.decode!(configuration.data)
    values_by_tabs = get_tab_keys(data)
    attribute_keys = get_attribute_keys(values_by_tabs, data)

    socket =
      socket
      |> assign(:game, game)
      |> assign(:configuration_group, configuration_group)
      |> assign(:configuration, configuration)
      |> assign(:data, data)
      |> assign(:values_by_tabs, values_by_tabs)
      |> assign(:attribute_keys, attribute_keys)
      |> assign(:data, data)

    {:ok, socket}
  end

  defp get_tab_keys(configuration) do
    tabs = Enum.map(configuration, fn {key, _value} -> key end)

    values_by_tabs =
      Enum.reduce(tabs, %{}, fn tab, acc ->
        tab_keys = Map.keys(configuration[tab])
        Map.put(acc, tab, tab_keys)
      end)

    values_by_tabs
  end

  defp get_attribute_keys(values_by_tabs, configuration) do
    Enum.reduce(values_by_tabs, [], fn {tab, tab_keys}, attributes_acc ->
      Enum.reduce(tab_keys, attributes_acc, fn tab_key, attributes_acc ->
        if is_map(configuration[tab][tab_key]) do
          attributes_acc ++ Map.keys(configuration[tab][tab_key])
        else
          [tab_key | attributes_acc]
        end
      end)
    end)
    |> Enum.uniq()
  end
end
