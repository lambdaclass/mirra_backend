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

  def render_form_for_map(assigns) do
    ~H"""
    <% form = to_form(@map) %>
    <.form for={form} phx-change="validate" phx-submit="save">
      <table>
        <thead>
          <tr>
            <th><%= @name %></th>
            <%= for key <- Map.keys(@map) do %>
              <th>
                <.label for={key}><%= ConfiguratorWeb.UtilsConfiguration.key_prettier(key) %></.label>
              </th>
            <% end %>
          </tr>
        </thead>
        <tbody>
          <td></td>
          <%= for key <- Map.keys(@map) do %>
            <td>
              <.input type="numeric" field={form[key]} />
            </td>
          <% end %>
        </tbody>
      </table>
    </.form>
    """
  end
end
