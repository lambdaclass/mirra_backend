defmodule ConfiguratorWeb.ConfigurationLive.Configuration do
  use Phoenix.LiveView

  def render do
    render("configuration.html")
  end

  def mount(_, %{"config" => config}, socket) do
    json_string = config.data
    json_decoded = Jason.decode!(json_string)
    config_keys = process_keys(json_decoded)

    socket =
      socket
      |> assign(:keys, config_keys)
      |> assign(:data, json_decoded)
      |> assign(:selected_key, hd(config_keys))

    {:ok, socket}
  end

  defp process_keys(json) do
    Enum.reduce(json, [], fn {key, _v}, acc ->
      [key | acc]
    end)
  end

  def handle_event("select_key", %{"key" => key}, socket) do
    {:noreply, assign(socket, :selected_key, key)}
  end

  def render_field(assigns) when is_map(assigns) do
    ~H"""
    <%= for {key, value} <- assigns do %>
      <%= render_field(value) %>
    <% end %>
    """
  end

  def render_field(assigns) when is_list(assigns) do
    ~H"""
    <%= for field <- assigns do %>
      <%= render_field(field) %>
    <% end %>
    """
  end

  def render_field(assigns) when is_integer(assigns) or is_float(assigns) do
    ~H"""
    <input type="number" value={assigns} />
    """
  end

  def render_field(assigns) when is_boolean(assigns) do
    ~H"""
    <input type="checkbox" checked={assigns} />
    """
  end

  def render_field(assigns) when is_binary(assigns) do
    ~H"""
    <input type="text" value={assigns} />
    """
  end

  def type(type) when is_integer(type) or is_float(type), do: "number"
  def type(_type), do: "text"
end
