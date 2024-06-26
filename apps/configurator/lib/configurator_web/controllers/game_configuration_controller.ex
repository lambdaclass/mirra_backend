defmodule ConfiguratorWeb.GameConfigurationController do
  use ConfiguratorWeb, :controller

  alias GameBackend.Configuration
  alias GameBackend.CurseOfMirra.GameConfiguration

  def index(conn, _params) do
    game_configurations = Configuration.list_game_configurations()
    render(conn, :index, game_configurations: game_configurations)
  end

  def new(conn, _params) do
    changeset = Configuration.change_game_configuration(%GameConfiguration{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"game_configuration" => game_configuration_params}) do
    case Configuration.create_game_configuration(game_configuration_params) do
      {:ok, game_configuration} ->
        conn
        |> put_flash(:info, "Game configuration created successfully.")
        |> redirect(to: ~p"/game_configurations/#{game_configuration}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    game_configuration = Configuration.get_game_configuration!(id)
    render(conn, :show, game_configuration: game_configuration)
  end

  def edit(conn, %{"id" => id}) do
    game_configuration = Configuration.get_game_configuration!(id)
    changeset = Configuration.change_game_configuration(game_configuration)
    render(conn, :edit, game_configuration: game_configuration, changeset: changeset)
  end

  def update(conn, %{"id" => id, "game_configuration" => game_configuration_params}) do
    game_configuration = Configuration.get_game_configuration!(id)

    case Configuration.update_game_configuration(game_configuration, game_configuration_params) do
      {:ok, game_configuration} ->
        conn
        |> put_flash(:info, "Game configuration updated successfully.")
        |> redirect(to: ~p"/game_configurations/#{game_configuration}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, game_configuration: game_configuration, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    game_configuration = Configuration.get_game_configuration!(id)
    {:ok, _game_configuration} = Configuration.delete_game_configuration(game_configuration)

    conn
    |> put_flash(:info, "Game configuration deleted successfully.")
    |> redirect(to: ~p"/game_configurations")
  end
end
