defmodule ConfiguratorWeb.GameModeController do
  use ConfiguratorWeb, :controller

  alias GameBackend.Configuration
  alias GameBackend.Configuration.GameMode

  def index(conn, _params) do
    game_modes = Configuration.list_game_modes()
    render(conn, :index, game_modes: game_modes)
  end

  def new(conn, _params) do
    changeset = Configuration.change_game_mode(%GameMode{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"game_mode" => game_mode_params}) do
    case Configuration.create_game_mode(game_mode_params) do
      {:ok, game_mode} ->
        conn
        |> put_flash(:info, "Game mode created successfully.")
        |> redirect(to: ~p"/game_modes/#{game_mode}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    game_mode = Configuration.get_game_mode!(id)
    render(conn, :show, game_mode: game_mode)
  end

  def edit(conn, %{"id" => id}) do
    game_mode = Configuration.get_game_mode!(id)
    changeset = Configuration.change_game_mode(game_mode)
    render(conn, :edit, game_mode: game_mode, changeset: changeset)
  end

  def update(conn, %{"id" => id, "game_mode" => game_mode_params}) do
    game_mode = Configuration.get_game_mode!(id)

    case Configuration.update_game_mode(game_mode, game_mode_params) do
      {:ok, game_mode} ->
        conn
        |> put_flash(:info, "Game mode updated successfully.")
        |> redirect(to: ~p"/game_modes/#{game_mode}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, game_mode: game_mode, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    game_mode = Configuration.get_game_mode!(id)
    {:ok, _game_mode} = Configuration.delete_game_mode(game_mode)

    conn
    |> put_flash(:info, "Game mode deleted successfully.")
    |> redirect(to: ~p"/game_modes")
  end
end
