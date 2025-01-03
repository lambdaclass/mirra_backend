defmodule ConfiguratorWeb.GameModeConfigurationController do
  use ConfiguratorWeb, :controller

  alias GameBackend.CurseOfMirra.MapModeParams.InitialPosition
  alias GameBackend.CurseOfMirra.MapModeParams
  alias GameBackend.Configuration
  alias GameBackend.CurseOfMirra.GameModeConfiguration

  def index(conn, %{"version_id" => version_id}) do
    game_mode_configurations = Configuration.list_game_mode_configurations_by_version(version_id)
    render(conn, :index, game_mode_configurations: game_mode_configurations, version_id: version_id)
  end

  def new(conn, %{"version_id" => version_id}) do
    changeset = Configuration.change_game_mode_configuration(%GameModeConfiguration{})
    version = Configuration.get_version!(version_id)
    maps = Configuration.list_map_configurations_by_version(version_id)

    render(conn, :new, changeset: changeset, version: version, maps: maps)
  end

  def create(conn, %{"game_mode_configuration" => game_mode_configuration_params}) do
    case Configuration.create_game_mode_configuration(game_mode_configuration_params) do
      {:ok, game_mode_configuration} ->
        conn
        |> put_flash(:info, "Game Mode configuration created successfully.")
        |> redirect(to: ~p"/versions/#{game_mode_configuration.version_id}/game_mode_configurations/#{game_mode_configuration}")

      {:error, %Ecto.Changeset{} = changeset} ->
        version = Configuration.get_version!(game_mode_configuration_params["version_id"])
        render(conn, :new, changeset: changeset, version: version)
    end
  end

  def show(conn, %{"id" => id}) do
    game_mode_configuration = Configuration.get_game_mode_configuration!(id)
    version = Configuration.get_version!(game_mode_configuration.version_id)
    render(conn, :show, game_mode_configuration: game_mode_configuration, version: version)
  end

  def edit(conn, %{"id" => id}) do
    game_mode_configuration = Configuration.get_game_mode_configuration!(id)
    changeset = Configuration.change_game_mode_configuration(game_mode_configuration)
    changeset =
      if Enum.empty?(game_mode_configuration.map_mode_params) do
        Ecto.Changeset.put_change(changeset, :map_mode_params, [%MapModeParams{initial_positions: [%InitialPosition{}]}])
      else
        changeset
      end

    maps = Configuration.list_map_configurations_by_version(game_mode_configuration.version_id)

    version = Configuration.get_version!(game_mode_configuration.version_id)
    render(conn, :edit, game_mode_configuration: game_mode_configuration, changeset: changeset, version: version, maps: maps)
  end

  def update(conn, %{"id" => id, "game_mode_configuration" => game_mode_configuration_params}) do
    game_mode_configuration = Configuration.get_game_mode_configuration!(id)
    game_mode_configuration_params = Map.update(game_mode_configuration_params, "map_mode_params", "",
    &ConfiguratorWeb.MapConfigurationController.parse_json_params/1)

    case Configuration.update_game_mode_configuration(game_mode_configuration, game_mode_configuration_params) do
      {:ok, game_mode_configuration} ->
        conn
        |> put_flash(:info, "Game Mode configuration updated successfully.")
        |> redirect(to: ~p"/versions/#{game_mode_configuration.version_id}/game_mode_configurations/#{game_mode_configuration}")

      {:error, %Ecto.Changeset{} = changeset} ->
        version = Configuration.get_version!(game_mode_configuration.version_id)
        maps = Configuration.list_map_configurations_by_version(game_mode_configuration.version_id)

        render(conn, :edit, game_mode_configuration: game_mode_configuration, changeset: changeset, version: version, maps: maps)
    end
  end

  def delete(conn, %{"id" => id}) do
    game_mode_configuration = Configuration.get_game_mode_configuration!(id)
    version_id = game_mode_configuration.version_id
    {:ok, _game_mode_configuration} = Configuration.delete_game_mode_configuration(game_mode_configuration)

    conn
    |> put_flash(:info, "Game Mode configuration deleted successfully.")
    |> redirect(to: ~p"/versions/#{version_id}/game_mode_configurations")
  end
end
