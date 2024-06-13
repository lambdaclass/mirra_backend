defmodule ConfiguratorWeb.UtilsConfiguration do
  @moduledoc """
  Module with utility functions for configuration data.
  """
  use Phoenix.Component

  def key_prettier(key) do
    key
    |> String.split("_")
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  def extract_keys(data) when is_list(data) do
    Enum.flat_map(data, &Map.keys/1)
    |> Enum.uniq()
  end

  def printable(val) when is_map(val), do: "map here"
  def printable(val) when is_list(val), do: "list here"
  def printable(val), do: val

  def table_cell(%{valor: [e | _] = valor} = assigns) when is_list(valor) and is_map(e) do
    tabla(%{data: valor})
  end
  def table_cell(%{valor: valor} = assigns) when is_list(valor) do
    ~H"""
    <td><%= Enum.join(@valor, ", ") %></td>
    """
  end
  def table_cell(%{valor: valor} = assigns) when is_map(valor) do
    tabla(%{data: [valor]})
  end
  def table_cell(assigns) do
    ~H"""
    <td><%= to_string(@valor) %></td>
    """
  end

  # def process_data(data) when is_map(data) do
  #   Map.to_list(data)
  #   |> Enum.sort_by(&elem(&1, 0))
  #   |> Enum.
  # end

  def tabla(assigns) do
    # assigns = Map.update(assigns, :data, fn data -> process_data(data) end)
    ~H"""
    <table class="config-table ">
      <thead>
        <tr>
          <%= for key <- extract_keys(@data) do %>
            <th><%= ConfiguratorWeb.UtilsConfiguration.key_prettier(key) %></th>
          <% end %>
        </tr>
      </thead>
      <tbody>
        <%= for value <- @data do %>
          <tr>
            <%= for key <- extract_keys(@data) do %>
              <% IO.inspect(Map.get(value, key, "")) %>
              <%!-- <ConfiguratorWeb.UtilsConfiguration.table_cell valor={Map.get(value, key, "")} /> --%>
              <td><%= Map.get(value, key, "") |> printable() %></td>
            <% end %>
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end
end
