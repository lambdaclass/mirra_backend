defmodule ConfiguratorWeb.VersionController do
  use ConfiguratorWeb, :controller

  alias GameBackend.Configuration
  alias GameBackend.Configuration.Version

  def index(conn, _params) do
    versions = Configuration.list_versions()
    render(conn, :index, versions: versions)
  end

  def new(conn, _params) do
    changeset = Configuration.change_version(%Version{})
    game_modes = Configuration.list_game_modes()

    render(conn, :new, changeset: changeset, game_modes: game_modes)
  end

  def create(conn, %{"version" => version_params}) do
    case Configuration.create_version(version_params) do
      {:ok, version} ->
        conn
        |> put_flash(:info, "Version created successfully.")
        |> redirect(to: ~p"/versions/#{version}")

      {:error, %Ecto.Changeset{} = changeset} ->
        game_modes = Configuration.list_game_modes()
        render(conn, :new, changeset: changeset, game_modes: game_modes)
    end
  end

  def show(conn, %{"id" => id}) do
    version = Configuration.get_version!(id)
    game_mode = Configuration.get_game_mode!(version.game_mode_id)
    render(conn, :show, version: version, game_mode: game_mode)
  end

  def edit(conn, %{"id" => id}) do
    version = Configuration.get_version!(id)
    changeset = Configuration.change_version(version)
    game_modes = Configuration.list_game_modes()

    render(conn, :edit, version: version, changeset: changeset, game_modes: game_modes)
  end

  def update(conn, %{"id" => id, "version" => version_params}) do
    version = Configuration.get_version!(id)

    case Configuration.update_version(version, version_params) do
      {:ok, version} ->
        conn
        |> put_flash(:info, "Version updated successfully.")
        |> redirect(to: ~p"/versions/#{version}")

      {:error, %Ecto.Changeset{} = changeset} ->
        game_modes = Configuration.list_game_modes()
        render(conn, :edit, version: version, changeset: changeset, game_modes: game_modes)
    end
  end

  def delete(conn, %{"id" => id}) do
    version = Configuration.get_version!(id)
    {:ok, _version} = Configuration.delete_version(version)

    conn
    |> put_flash(:info, "Version deleted successfully.")
    |> redirect(to: ~p"/versions")
  end

  def mark_as_current(conn, %{"id" => id}) do
    version = Configuration.get_version!(id)

    case Configuration.mark_as_current_version(version) do
      {:ok, _version} ->
        conn
        |> put_flash(:info, "Version marked as current.")
        |> redirect(to: ~p"/versions")

      {:error, _failed_action, _changeset, _changes_so_far} ->
        conn
        |> put_flash(:error, "Failed to mark version as current.")
        |> redirect(to: ~p"/versions")
    end
  end
end
