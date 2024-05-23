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

  def handle_event("select_key", %{"key" => key}, socket) do
    {:noreply, assign(socket, :selected_key, key)}
  end

  def handle_event("validate", %{"_target" => ["game", field], "game" => game} = params, socket) do
    data = put_in(socket.assigns.data, ["game", field], game[field])
    socket = assign(socket, :data, data)
    {:noreply, socket}
  end

  def handle_event("save", params, socket) do
    {:noreply, socket}
  end

  defp process_keys(json) do
    Enum.reduce(json, [], fn {key, _v}, acc ->
      [key | acc]
    end)
  end

  def input(assigns) do
    ~H"""
    <input id={@field.id} name={@field.name} value={@field.value} type={@type} label={@label} />
    """
  end

  def type(type) when is_integer(type) or is_float(type), do: "number"
  def type(type) when is_boolean(type), do: "checkbox"
  def type(_type), do: "text"
end
