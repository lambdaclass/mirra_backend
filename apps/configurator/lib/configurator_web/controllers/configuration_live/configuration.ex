defmodule ConfiguratorWeb.ConfigurationLive.Configuration do
  use ConfiguratorWeb, :html
  use Phoenix.LiveView
  use Phoenix.Component

  alias Configurator.Configure

  def render do
    render("configuration.html")
  end

  def mount(_, %{"config" => config}, socket) do
    json_string = config.data
    json_decoded = Jason.decode!(json_string)
    config_keys = process_keys(json_decoded)

    # json_decoded =
    #   Enum.reduce(json_decoded, %{}, fn {key, value}, acc ->
    #     if is_list(value) do
    #       new_effects_map =
    #         Enum.into(Enum.with_index(value), %{}, fn {effect, index} ->
    #           {"#{index}", effect}
    #         end)

    #       Map.put(acc, key, new_effects_map)
    #     else
    #       Map.put(acc, key, value)
    #     end
    #   end)

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

  # def handle_event("validate", %{"_target" => ["game", field], "game" => game} = params, socket) do
  #   data = put_in(socket.assigns.data, ["game", field], game[field])

  #   socket =
  #     socket
  #     |> assign(:data, data)
  #     |> assign(:form, to_form(data))

  #   {:noreply, socket}
  # end

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

  def render_game_form(assigns) do
    ~H"""
    <.inputs_for :let={game_form} field={@form[@selected_key]} id={@selected_key} as={@selected_key}>
      <.label for="tick_rate_ms">Tick Rate (ms)</.label>
      <.input type="number" field={game_form["tick_rate_ms"]} />

      <.label for="start_game_time_ms">Start Game Time (ms)</.label>
      <.input type="number" field={game_form["start_game_time_ms"]} />

      <.label for="end_game_interval_ms">End Game Interval (ms)</.label>
      <.input type="number" field={game_form["end_game_interval_ms"]} />

      <.label for="shutdown_game_wait_ms">Shutdown Game Wait (ms)</.label>
      <.input type="number" field={game_form["shutdown_game_wait_ms"]} />

      <.label for="natural_healing_interval_ms">Natural Healing Interval (ms)</.label>
      <.input type="number" field={game_form["natural_healing_interval_ms"]} />

      <.label for="zone_shrink_start_ms">Zone Shrink Start (ms)</.label>
      <.input type="number" field={game_form["zone_shrink_start_ms"]} />

      <.label for="zone_shrink_radius_by">Zone Shrink Radius By</.label>
      <.input type="number" field={game_form["zone_shrink_radius_by"]} />

      <.label for="zone_shrink_interval">Zone Shrink Interval</.label>
      <.input type="number" field={game_form["zone_shrink_interval"]} />

      <.label for="zone_stop_interval_ms">Zone Stop Interval (ms)</.label>
      <.input type="number" field={game_form["zone_stop_interval_ms"]} />

      <.label for="zone_start_interval_ms">Zone Start Interval (ms)</.label>
      <.input type="number" field={game_form["zone_start_interval_ms"]} />

      <.label for="zone_damage_interval_ms">Zone Damage Interval (ms)</.label>
      <.input type="number" field={game_form["zone_damage_interval_ms"]} />

      <.label for="zone_damage">Zone Damage</.label>
      <.input type="number" field={game_form["zone_damage"]} />

      <.label for="item_spawn_interval_ms">Item Spawn Interval (ms)</.label>
      <.input type="number" field={game_form["item_spawn_interval_ms"]} />
    </.inputs_for>
    """
  end

  def render_effects_form(assigns) do
    ~H"""
    <.inputs_for :let={effects_form} field={@form[@selected_key]} } as={@selected_key} id={@selected_key}>
      <%= for {effect_key, effect_data} <- @data[@selected_key] do %>
        <.inputs_for :let={effect_form} field={effects_form[effect_key]}>
          <div class="border rounded-md p-1 m-1 bg-green-300">
            <%= for {effect_data_key, effect_data_value} <- effect_data do %>
              <%= unless is_map(effect_data_value) do %>
                <div class="flex items-center">
                  <.label for={effect_data_key}><%= effect_data_key %></.label>
                  <.input
                    type={type(effect_data_value)}
                    field={effect_form[effect_data_key]}
                    value={@data[@selected_key][effect_data_key]}
                  />
                </div>
              <% else %>
                <.render_effect_mechanics_form data={effect_data_value} effect_form={effect_form} />
              <% end %>
            <% end %>
          </div>
        </.inputs_for>
      <% end %>
    </.inputs_for>
    """
  end

  def render_effect_mechanics_form(assigns) do
    ~H"""
    <.inputs_for :let={effects_mechanics_form} field={@effect_form["effect_mechanics"]}>
      <%= for {effect_mechanic_name, effect_mechanic_values} <- @data do %>
        <.inputs_for :let={effect_mechanics_form} field={effects_mechanics_form[effect_mechanic_name]}>
          <div class="border rounded-md bg-blue-100 p-1 m-1">
            <span><%= "Effect mechanic #{String.capitalize(effect_mechanic_name)}" %></span>
            <%= for {effect_mechanic_data_key, effect_mechanic_data_value} <- @data[effect_mechanic_name] do %>
              <div class="flex items-center">
                <.label for={effect_mechanic_data_key}><%= effect_mechanic_data_key %></.label>
                <.input type={type(effect_mechanic_data_value)} field={effect_mechanics_form[effect_mechanic_data_key]} />
              </div>
            <% end %>
          </div>
        </.inputs_for>
      <% end %>
    </.inputs_for>
    """
  end

  def type(type) when is_integer(type) or is_float(type), do: "number"
  def type(type) when is_boolean(type), do: "checkbox"
  def type(_type), do: "text"
end
