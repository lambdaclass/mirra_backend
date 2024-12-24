defmodule ConfiguratorWeb.VersionController do
  use ConfiguratorWeb, :controller
  alias ConfiguratorWeb.MapConfigurationController

  alias GameBackend.Configuration
  alias GameBackend.Configuration.Version
  alias GameBackend.Utils

  def index(conn, _params) do
    versions = Configuration.list_versions()
    render(conn, :index, versions: versions)
  end

  def new(conn, _params) do
    map_params = Arena.Configuration.get_current_map_configuration_for_configurator()
    last_version = GameBackend.Configuration.get_current_version()
    skills = Utils.list_curse_skills_by_version_grouped_by_type(last_version.id)

    params =
      Map.from_struct(last_version)
      |> Map.put(:characters, schema_to_map(last_version.characters))
      |> Map.put(:consumable_items, schema_to_map(last_version.consumable_items))
      |> Map.put(:game_configuration, schema_to_map(last_version.game_configuration))
      |> Map.put(:map_configurations, map_params)
      |> Map.put(:skills, schema_to_map(last_version.skills))

    changeset = Configuration.change_version(%Version{}, params)
    render(conn, :new, changeset: changeset, last_version: last_version, skills: skills)
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

  def create(conn, %{"version" => version_params}) do
    version_params =
      Map.put(
        version_params,
        "map_configurations",
        Map.new(version_params["map_configurations"], fn {key, map_params} ->
          {key, MapConfigurationController.parse_json_params(map_params)}
        end)
      )

    case Configuration.create_version(version_params) do
      {:ok, version} ->
        conn
        |> put_flash(:info, "Version created successfully.")
        |> redirect(to: ~p"/versions/#{version}")

      {:error, %Ecto.Changeset{} = changeset} ->
        last_version = GameBackend.Configuration.get_current_version()
        skills = Utils.list_curse_skills_by_version_grouped_by_type(last_version.id)

        render(conn, :new, changeset: changeset, last_version: last_version, skills: skills)
    end
  end

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
