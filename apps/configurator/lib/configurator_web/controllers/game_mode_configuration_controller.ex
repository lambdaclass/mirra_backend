defmodule ConfiguratorWeb.GameModeConfigurationController do
  use ConfiguratorWeb, :controller

  alias GameBackend.Configuration

  def index(conn, %{"version_id" => version_id}) do
    game_mode_configurations = Configuration.list_game_mode_configurations_by_version(version_id)
    render(conn, :index, game_mode_configurations: game_mode_configurations, version_id: version_id)
  end

  def new(conn, %{"version_id" => version_id}) do
    version = Configuration.get_version!(version_id)

    render(conn, :new, version: version)
  end

  def show(conn, %{"id" => id}) do
    game_mode_configuration = Configuration.get_game_mode_configuration!(id)
    version = Configuration.get_version!(game_mode_configuration.version_id)
    render(conn, :show, game_mode_configuration: game_mode_configuration, version: version)
  end

  def edit(conn, %{"id" => id}) do
    game_mode_configuration = Configuration.get_game_mode_configuration!(id)
    version = Configuration.get_version!(game_mode_configuration.version_id)

    render(conn, :edit, game_mode_configuration: game_mode_configuration, version: version)
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
