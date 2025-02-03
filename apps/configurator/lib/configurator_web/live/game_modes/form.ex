defmodule ConfiguratorWeb.GameModeConfigurationsLive.Form do
  use ConfiguratorWeb, :live_view

  alias GameBackend.CurseOfMirra.GameModeConfiguration
  alias GameBackend.CurseOfMirra.MapModeParams
  alias GameBackend.Configuration
  alias Configurator.Utils

  def mount(
        _params,
        %{"game_mode_configuration" => game_mode_configuration, "version" => version},
        socket
      ) do
    maps = Configuration.list_map_configurations_by_version(version.id)
    changeset = Configuration.change_game_mode_configuration(game_mode_configuration)

    socket =
      assign(socket,
        changeset: changeset,
        action: "update",
        maps: maps,
        version: version,
        game_mode_configuration: game_mode_configuration,
        team_mode: game_mode_configuration.team_enabled
      )

    {:ok, socket}
  end

  def mount(
        _params,
        %{"version" => version},
        socket
      ) do
    changeset = Configuration.change_game_mode_configuration(%GameModeConfiguration{})
    maps = Configuration.list_map_configurations_by_version(version.id)

    socket =
      assign(socket,
        changeset: changeset,
        action: "save",
        maps: maps,
        version: version,
        game_mode_configuration: %{},
        team_mode: false
      )

    {:ok, socket}
  end

  def handle_event("validate", %{"_target" => ["game_mode_configuration", "team_enabled"]} = params, socket) do
    {:noreply, assign(socket, :team_mode, params["game_mode_configuration"]["team_enabled"] == "true")}
  end

  def handle_event("validate", %{"game_mode_configuration" => game_mode_configuration_params}, socket) do
    changeset = socket.assigns.changeset
    changeset = GameModeConfiguration.changeset(changeset, game_mode_configuration_params)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("add_map_params", _params, socket) do
    changeset = socket.assigns.changeset
    map_mode_params = Ecto.Changeset.get_field(changeset, :map_mode_params) || []
    new_map_mode_params = MapModeParams.changeset(%MapModeParams{}, %{})
    changeset = Ecto.Changeset.put_assoc(changeset, :map_mode_params, [new_map_mode_params | map_mode_params])

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("remove_map_params", _params, socket) do
    changeset = socket.assigns.changeset
    map_mode_params = Ecto.Changeset.get_field(changeset, :map_mode_params) |> List.delete_at(-1)
    changeset = Ecto.Changeset.put_change(changeset, :map_mode_params, map_mode_params)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"game_mode_configuration" => game_mode_configuration_params}, socket) do
    game_mode_configuration_params = parse_game_mode_params(game_mode_configuration_params)

    socket =
      case Configuration.create_game_mode_configuration(game_mode_configuration_params) do
        {:ok, game_mode_configuration} ->
          socket
          |> put_flash(:info, "Game Mode created successfully.")
          |> redirect(
            to:
              ~p"/versions/#{game_mode_configuration.version_id}/game_mode_configurations/#{game_mode_configuration.id}"
          )

        {:error, %Ecto.Changeset{} = changeset} ->
          version = Configuration.get_version!(game_mode_configuration_params["version_id"])

          socket
          |> put_flash(:error, "Please correct the errors below.")
          |> assign(changeset: changeset, version: version)
      end

    {:noreply, socket}
  end

  def handle_event("update", %{"game_mode_configuration" => game_mode_configuration_params}, socket) do
    game_mode_configuration = socket.assigns.game_mode_configuration
    game_mode_configuration_params = parse_game_mode_params(game_mode_configuration_params)

    socket =
      case Configuration.update_game_mode_configuration(game_mode_configuration, game_mode_configuration_params) do
        {:ok, game_mode_configuration} ->
          socket
          |> put_flash(:info, "Game Mode updated successfully.")
          |> redirect(
            to:
              ~p"/versions/#{game_mode_configuration.version_id}/game_mode_configurations/#{game_mode_configuration.id}"
          )

        {:error, %Ecto.Changeset{} = changeset} ->
          version = Configuration.get_version!(game_mode_configuration.version_id)

          socket
          |> put_flash(:error, "Please correct the errors below.")
          |> assign(changeset: changeset, version: version)
      end

    {:noreply, socket}
  end

  defp parse_game_mode_params(game_mode_params) do
    case Map.get(game_mode_params, "map_mode_params") do
      nil ->
        game_mode_params

      map_mode_params ->
        Map.put(
          game_mode_params,
          "map_mode_params",
          Map.new(map_mode_params, fn {key, params} ->
            {key, Utils.parse_json_params(params)}
          end)
        )
    end
  end
end
