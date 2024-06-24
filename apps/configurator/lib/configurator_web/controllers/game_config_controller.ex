defmodule ConfiguratorWeb.GameConfigController do
  use ConfiguratorWeb, :controller

  alias Configurator.Configuration
  alias Configurator.Configuration.GameConfig

  def index(conn, _params) do
    game_configurations = Configuration.list_game_configurations()
    render(conn, :index, game_configurations: game_configurations)
  end

  def new(conn, _params) do
    changeset = Configuration.change_game_config(%GameConfig{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"game_config" => game_config_params}) do
    case Configuration.create_game_config(game_config_params) do
      {:ok, game_config} ->
        conn
        |> put_flash(:info, "Game config created successfully.")
        |> redirect(to: ~p"/game_configurations/#{game_config}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    game_config = Configuration.get_game_config!(id)
    render(conn, :show, game_config: game_config)
  end

  def edit(conn, %{"id" => id}) do
    game_config = Configuration.get_game_config!(id)
    changeset = Configuration.change_game_config(game_config)
    render(conn, :edit, game_config: game_config, changeset: changeset)
  end

  def update(conn, %{"id" => id, "game_config" => game_config_params}) do
    game_config = Configuration.get_game_config!(id)

    case Configuration.update_game_config(game_config, game_config_params) do
      {:ok, game_config} ->
        conn
        |> put_flash(:info, "Game config updated successfully.")
        |> redirect(to: ~p"/game_configurations/#{game_config}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, game_config: game_config, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    game_config = Configuration.get_game_config!(id)
    {:ok, _game_config} = Configuration.delete_game_config(game_config)

    conn
    |> put_flash(:info, "Game config deleted successfully.")
    |> redirect(to: ~p"/game_configurations")
  end
end
