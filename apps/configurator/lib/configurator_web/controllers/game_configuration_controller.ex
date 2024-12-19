defmodule ConfiguratorWeb.GameConfigurationController do
  use ConfiguratorWeb, :controller

  alias GameBackend.Configuration
  alias GameBackend.CurseOfMirra.GameConfiguration

  def index(conn, %{"id" => version_id}) do
    game_configurations = Configuration.list_game_configurations_by_version(version_id)
    render(conn, :index, game_configurations: game_configurations, version_id: version_id)
  end

  def new(conn, %{"id" => version_id}) do
    changeset = Configuration.change_game_configuration(%GameConfiguration{})
    version = Configuration.get_version!(version_id)
    render(conn, :new, changeset: changeset, version: version)
  end

  def create(conn, %{"game_configuration" => game_configuration_params}) do
    case Configuration.create_game_configuration(game_configuration_params) do
      {:ok, game_configuration} ->
        conn
        |> put_flash(:info, "Game configuration created successfully.")
        |> redirect(to: ~p"/versions/#{game_configuration.version_id}/game_configurations/#{game_configuration}")

      {:error, %Ecto.Changeset{} = changeset} ->
        version = Configuration.get_version!(game_configuration_params["version_id"])
        render(conn, :new, changeset: changeset, version: version)
    end
  end

  def show(conn, %{"id" => id}) do
    game_configuration = Configuration.get_game_configuration!(id)
    version = Configuration.get_version!(game_configuration.version_id)
    render(conn, :show, game_configuration: game_configuration, version: version)
  end

  def edit(conn, %{"id" => id}) do
    game_configuration = Configuration.get_game_configuration!(id)
    changeset = Configuration.change_game_configuration(game_configuration)
    version = Configuration.get_version!(game_configuration.version_id)
    render(conn, :edit, game_configuration: game_configuration, changeset: changeset, version: version)
  end

  def update(conn, %{"id" => id, "game_configuration" => game_configuration_params}) do
    game_configuration = Configuration.get_game_configuration!(id)

    case Configuration.update_game_configuration(game_configuration, game_configuration_params) do
      {:ok, game_configuration} ->
        conn
        |> put_flash(:info, "Game configuration updated successfully.")
        |> redirect(to: ~p"/versions/#{game_configuration.version_id}/game_configurations/#{game_configuration}")

      {:error, %Ecto.Changeset{} = changeset} ->
        version = Configuration.get_version!(game_configuration.version_id)
        render(conn, :edit, game_configuration: game_configuration, changeset: changeset, version: version)
    end
  end

  def delete(conn, %{"id" => id}) do
    game_configuration = Configuration.get_game_configuration!(id)
    version_id = game_configuration.version_id
    {:ok, _game_configuration} = Configuration.delete_game_configuration(game_configuration)

    conn
    |> put_flash(:info, "Game configuration deleted successfully.")
    |> redirect(to: ~p"/versions/#{version_id}/game_configurations")
  end
end
