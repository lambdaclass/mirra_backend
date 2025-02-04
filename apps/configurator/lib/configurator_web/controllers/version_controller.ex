defmodule ConfiguratorWeb.VersionController do
  use ConfiguratorWeb, :controller

  require Logger
  alias GameBackend.Configuration
  alias GameBackend.Configuration.Version

  def index(conn, _params) do
    versions = Configuration.list_versions()
    render(conn, :index, versions: versions)
  end

  def new(conn, _params) do
    changeset = Configuration.change_version(%Version{})
    render(conn, :new, changeset: changeset, skills: [])
  end

  def create(conn, %{"version" => version_params}) do
    case Configuration.create_version(version_params) do
      {:ok, version} ->
        conn
        |> put_flash(:info, "Version created successfully.")
        |> redirect(to: ~p"/versions/#{version}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset, skills: [])
    end
  end

  def copy(conn, _params) do
    versions = Configuration.list_versions()
    render(conn, :copy, versions: versions)
  end

  def create_copy(conn, params) do
    selected_version = Configuration.get_preloaded_version!(params["version_id"])

    params =
      Map.from_struct(selected_version)
      |> Map.put(:characters, schema_to_map(selected_version.characters))
      |> Map.put(:consumable_items, schema_to_map(selected_version.consumable_items))
      |> Map.put(:game_configuration, schema_to_map(selected_version.game_configuration))
      |> Map.put(:map_configurations, schema_to_map(selected_version.map_configurations))
      |> Map.put(:skills, schema_to_map(selected_version.skills))
      |> Map.put(:name, params["name"])
      |> Map.put(:current, false)

    case Configuration.copy_version(params) do
      {:ok, %{version: version}} ->
        conn
        |> put_flash(:info, "Version created successfully.")
        |> redirect(to: ~p"/versions/#{version}")

      {:error, :version, %Ecto.Changeset{} = changeset, _changes_so_far} ->
        Logger.info("Insertion failed. Changeset: #{changeset}")
        versions = Configuration.list_versions()
        render(conn, :index, versions: versions)

      {:error, :link_character_skills, %Ecto.Changeset{} = changeset, _changes_so_far} ->
        Logger.info("Link character skills failed. Changeset: #{changeset}")
        versions = Configuration.list_versions()
        render(conn, :index, versions: versions)
    end
  end

  # TODO: We have a cycle in our Skill.Mechanic assocs so this is to end that loop.
  # This replaces the unloaded mechanics assoc by an empty list.
  # The key is that we preload the necessary steps of the mechanics loop associations.
  # https://github.com/lambdaclass/mirra_backend/issues/1028
  def schema_to_map(%{
        __cardinality__: :many,
        __field__: _,
        __owner__: _
      }) do
    []
  end

  def schema_to_map(%Decimal{} = decimal), do: decimal

  def schema_to_map(%_struct{} = schema) do
    schema
    # Here we drop the keys we don't need because the assocs are linked already.
    |> Map.reject(fn {field, _value} ->
      field in [
        :on_arrival_mechanic_id,
        :parent_mechanic_id,
        :version_id,
        :dash_skill_id,
        :ultimate_skill_id,
        :basic_skill_id
      ]
    end)
    |> Map.from_struct()
    |> Enum.map(fn {key, value} -> {key, schema_to_map(value)} end)
    |> Enum.into(%{})
  end

  def schema_to_map(map) when is_map(map) do
    map
    |> Enum.map(fn {key, value} -> {key, schema_to_map(value)} end)
    |> Enum.into(%{})
  end

  def schema_to_map(list) when is_list(list) do
    Enum.map(list, &schema_to_map/1)
  end

  def schema_to_map(value), do: value

  def show(conn, %{"id" => id}) do
    version = Configuration.get_version!(id)
    render(conn, :show, version: version)
  end

  def show_current_version(conn, _params) do
    version = GameBackend.Configuration.get_current_version()
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
