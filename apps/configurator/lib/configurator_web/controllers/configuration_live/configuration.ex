defmodule ConfiguratorWeb.ConfigurationLive.Configuration do
  use ConfiguratorWeb, :html
  use Phoenix.LiveView
  use Phoenix.Component

  alias Configurator.Configure

  def render do
    render("configuration.html")
  end

  def mount(_, %{"configuration" => configuration}, socket) do
    json_string = configuration.data
    json_decoded = Jason.decode!(json_string)
    config_keys = process_keys(json_decoded)

    socket =
      socket
      |> assign(:keys, config_keys)
      |> assign(:data, json_decoded)
      |> assign(:form, to_form(json_decoded))
      |> assign(:selected_key, hd(config_keys))

    {:ok, socket}
  end

  def handle_event("select_key", %{"key" => key}, socket) do
    {:noreply, assign(socket, :selected_key, key)}
  end

  def handle_event("validate", params, socket) do
    {:noreply, socket}
  end

  def handle_event("save", params, socket) do
    params = %{
      data: Jason.encode!(params),
      is_default: false
    }

    socket =
      case Configure.create_configuration(params) do
        {:ok, configuration} ->
          socket
          |> put_flash(:info, "Configuration created successfully.")
          |> redirect(to: ~p"/configurations")

        {:error, %Ecto.Changeset{} = _changeset} ->
          socket
          |> put_flash(:error, "Failed to create configuration.")
      end

    {:noreply, socket}
  end

  defp process_keys(json) do
    Enum.reduce(json, [], fn {key, _v}, acc ->
      [key | acc]
    end)
  end

  def render_main_form(assigns) do
    ~H"""
    <.inputs_for :let={nested_form} field={@form[@selected_key]} id={@selected_key} as={@selected_key}>
      <div class="">
        <%= for {data_name, data_value} <- @data[@selected_key] do %>
          <%= if is_map(data_value) do %>
            <.render_nested_maps data={data_value} form={nested_form} field_name={data_name} />
          <% else %>
            <.label for={data_name}><%= data_name %></.label>
            <.custom_input value={data_value} field={nested_form[data_name]} />
          <% end %>
        <% end %>
      </div>
    </.inputs_for>
    """
  end

  def render_nested_maps(assigns) do
    ~H"""
    <.inputs_for :let={nested_form} field={@form[@field_name]}>
      <%= for {data_name, data_value} <- @data do %>
        <%= if is_map(data_value) do %>
          <.render_nested_maps data={data_value} form={nested_form} field_name={data_name} />
        <% else %>
          <.label for={data_name}><%= data_name %></.label>
          <.custom_input value={data_value} field={nested_form[data_name]} />
        <% end %>
      <% end %>
    </.inputs_for>
    """
  end

  def type(value) when is_integer(value) or is_float(value), do: "number"
  def type(value) when is_boolean(value), do: "checkbox"
  def type(value) when is_list(value), do: "list"
  def type(_type), do: "text"

  def custom_input(assigns) do
    ~H"""
    <%= case type(@value) do %>
      <% "number" -> %>
        <.input type="number" field={@field} value={@value} />
      <% "checkbox" -> %>
        <.input type="checkbox" field={@field} checked={@value} />
      <% "list" -> %>
        <.input type="select" field={@field} options={@value} value={@value} />
      <% "text" -> %>
        <.input type="text" field={@field} value={@value} />
    <% end %>
    """
  end
end
