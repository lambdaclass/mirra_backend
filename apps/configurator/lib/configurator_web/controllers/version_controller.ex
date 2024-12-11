defmodule ConfiguratorWeb.VersionController do
  use ConfiguratorWeb, :controller
  import Ecto.Query

  alias GameBackend.Configuration
  alias GameBackend.Configuration.Version

  def index(conn, _params) do
    versions = Configuration.list_versions()
    render(conn, :index, versions: versions)
  end

  def new(conn, _params) do
    _changeset = Configuration.change_version(%Version{})
    # list_all_version_settings
    # version_q = from v in GameBackend.Configuration.Version, order_by: [{:desc, :inserted_at}], limit: 1, select: v.id
    version_q = from v in GameBackend.Configuration.Version, order_by: [{:desc, :inserted_at}], limit: 1, preload: [:characters, :consumable_items, :skills, :game_configuration, :map_configurations]
    last_version = GameBackend.Repo.one(version_q)
    changeset = Configuration.change_version(last_version)
    # characters_q = from c in GameBackend.Units.Characters.Character, where: c.version_id == ^last_version_id
    # characters = GameBackend.Repo.all(characters_q)
    # consumable_items_q = from ci in GameBackend.Items.ConsumableItem, where: ci.version_id == ^last_version_id
    # consumable_items = GameBackend.Repo.all(consumable_items_q)
    # skills_q = from s in GameBackend.Units.Skills.Skill, where: s.version_id == ^last_version_id
    # skills = GameBackend.Repo.all(skills_q)
    # game_configurations_q = from gc in GameBackend.CurseOfMirra.GameConfiguration, where: gc.version_id == ^last_version_id
    # game_configurations = GameBackend.Repo.all(game_configurations_q)
    # map_configurations_q = from mc in GameBackend.CurseOfMirra.MapConfiguration, where: mc.version_id == ^last_version_id
    # map_configurations = GameBackend.Repo.all(map_configurations_q)

    render(conn, :new, changeset: changeset, last_version: last_version)
    # render(conn, :new, changeset: changeset, characters: characters, consumable_items: consumable_items, skills: skills, game_configurations: game_configurations, map_configurations: map_configurations)
  end

  def create(conn, %{"version" => version_params}) do
    case Configuration.create_version(version_params) do
      {:ok, version} ->
        conn
        |> put_flash(:info, "Version created successfully.")
        |> redirect(to: ~p"/versions/#{version}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    version = Configuration.get_version!(id)
    render(conn, :show, version: version)
  end

  def edit(conn, %{"id" => id}) do
    version = Configuration.get_version!(id)
    changeset = Configuration.change_version(version)
    render(conn, :edit, version: version, changeset: changeset)
  end

  def update(conn, %{"id" => id, "version" => version_params}) do
    version = Configuration.get_version!(id)

    case Configuration.update_version(version, version_params) do
      {:ok, version} ->
        conn
        |> put_flash(:info, "Version updated successfully.")
        |> redirect(to: ~p"/versions/#{version}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, version: version, changeset: changeset)
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
