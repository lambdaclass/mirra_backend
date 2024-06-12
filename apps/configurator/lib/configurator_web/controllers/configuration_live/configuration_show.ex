defmodule ConfiguratorWeb.ConfigurationLive.ConfigurationShow do
  use ConfiguratorWeb, :html
  use Phoenix.LiveView
  use Phoenix.Component

  def render do
    render("configuration_show.html")
  end

  def mount(
        _params,
        %{"game" => game, "configuration_group" => configuration_group, "configuration" => configuration},
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

  def render_map_as_table(assigns) do
    ~H"""
    <table class="config-table w-full">
      <thead>
        <tr>
          <th><%= ConfiguratorWeb.UtilsConfiguration.key_prettier(@name) %></th>
          <%= for key <- Map.keys(@map) do %>
            <th><%= ConfiguratorWeb.UtilsConfiguration.key_prettier(key) %></th>
          <% end %>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td></td>
          <%= for key <- Map.keys(@map) do %>
            <%= cond do %>
              <% is_map(@map[key]) -> %>
                <td>
                  <.maybe_render_map_as_plain_text map={@map[key]} name={"#{@name}_#{key}"} />
                </td>
              <% is_list(@map[key]) -> %>
                <td>
                  <.modal id={"#{@name}_#{key}"}>
                    <.render_list_as_table list={@map[key]} name={key} />
                  </.modal>
                  <.button phx-click={show_modal("#{@name}_#{key}")}>
                    Display <%= key %>
                  </.button>
                </td>
              <% true -> %>
                <td><%= @map[key] %></td>
            <% end %>
          <% end %>
        </tr>
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
        <%= for {value, index} <- Enum.with_index(@list) do %>
          <tr>
            <%= cond do %>
              <% is_map(value) -> %>
                <td>
                  <.maybe_render_map_as_plain_text map={value} name={"#{@name}_#{index}"} />
                </td>
              <% true -> %>
                <td><%= value %></td>
            <% end %>
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end

  def maybe_render_map_as_plain_text(assigns) do
    ~H"""
    <%= if map_size(@map) > 2 do %>
      <.modal id={@name}>
        <.render_map_as_table name={@name} map={@map} />
      </.modal>
      <.button phx-click={show_modal(@name)}>
        Display <%= @name %>
      </.button>
    <% else %>
      <%= Jason.encode!(@map) %>
    <% end %>
    """
  end
end
