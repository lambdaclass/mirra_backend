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

  def render_map_as_table(assigns) do
    ~H"""
    <table class="config-table w-full">
      <thead>
        <tr>
          <th><%= ConfiguratorWeb.UtilsConfiguration.key_prettier(@name) %></th>
          <th></th>
        </tr>
      </thead>
      <tbody>
        <%= for key <- Map.keys(@map) do %>
          <tr>
            <td><%= ConfiguratorWeb.UtilsConfiguration.key_prettier(key) %></td>
            <%= cond do %>
              <% is_map(@map[key]) -> %>
                <td>
                  <.modal id={key}>
                    <.render_map_as_table map={@map[key]} name={key} />
                  </.modal>
                  <.button phx-click={show_modal(key)}>
                    Display <%= key %>
                  </.button>
                </td>
              <% is_list(@map[key]) -> %>
                <td>
                  <.modal id={key}>
                    <.render_list_as_table list={@map[key]} name={key} />
                  </.modal>
                  <.button phx-click={show_modal(key)}>
                    Display <%= key %>
                  </.button>
                </td>
              <% true -> %>
                <td><%= @map[key] %></td>
            <% end %>
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end

  def render_list_as_table(assigns) do
    ~H"""
    <table class="config-table w-full">
      <thead>
        <tr>
          <th><%= ConfiguratorWeb.UtilsConfiguration.key_prettier(@name) %></th>
        </tr>
      </thead>
      <tbody>
        <%= for value <- @list do %>
          <tr>
            <% IO.inspect(value) %>
            <td><%= value %></td>
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end

  #############################
  ###### Private Helpers ######
  #############################
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
