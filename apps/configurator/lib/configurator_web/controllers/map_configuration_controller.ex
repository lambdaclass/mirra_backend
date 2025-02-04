defmodule ConfiguratorWeb.MapConfigurationController do
  use ConfiguratorWeb, :controller

  alias GameBackend.Configuration
  alias GameBackend.CurseOfMirra.MapConfiguration
  alias GameBackend.Configuration
  alias Configurator.Utils

  def index(conn, %{"version_id" => version_id}) do
    map_configurations = Configuration.list_map_configurations_by_version(version_id)
    render(conn, :index, map_configurations: map_configurations, version_id: version_id)
  end

  def new(conn, %{"version_id" => version_id}) do
    changeset = Configuration.change_map_configuration(%MapConfiguration{})
    version = Configuration.get_version!(version_id)
    render(conn, :new, changeset: changeset, version: version)
  end

  def create(conn, %{"map_configuration" => map_configuration_params}) do
    map_configuration_params = Utils.parse_json_params(map_configuration_params)

    case Configuration.create_map_configuration(map_configuration_params) do
      {:ok, map_configuration} ->
        conn
        |> put_flash(:info, "Map configuration created successfully.")
        |> redirect(to: ~p"/versions/#{map_configuration.version_id}/map_configurations/#{map_configuration}")

      {:error, %Ecto.Changeset{} = changeset} ->
        version = Configuration.get_version!(map_configuration_params["version_id"])
        render(conn, :new, changeset: changeset, version: version)
    end
  end

  def show(conn, %{"id" => id}) do
    map_configuration = Configuration.get_map_configuration!(id)
    version = Configuration.get_version!(map_configuration.version_id)
    render(conn, :show, map_configuration: map_configuration, version: version)
  end

  def edit(conn, %{"id" => id}) do
    map_configuration = Configuration.get_map_configuration!(id)
    version = Configuration.get_version!(map_configuration.version_id)
    changeset = Configuration.change_map_configuration(map_configuration)
    render(conn, :edit, map_configuration: map_configuration, changeset: changeset, version: version)
  end

  def update(conn, %{"id" => id, "map_configuration" => map_configuration_params}) do
    map_configuration = Configuration.get_map_configuration!(id)
    map_configuration_params = Utils.parse_json_params(map_configuration_params)

    case Configuration.update_map_configuration(map_configuration, map_configuration_params) do
      {:ok, map_configuration} ->
        conn
        |> put_flash(:info, "Map configuration updated successfully.")
        |> redirect(to: ~p"/versions/#{map_configuration.version_id}/map_configurations/#{map_configuration}")

      {:error, %Ecto.Changeset{} = changeset} ->
        version = Configuration.get_version!(map_configuration.version_id)
        render(conn, :edit, map_configuration: map_configuration, changeset: changeset, version: version)
    end
  end

  def delete(conn, %{"id" => id}) do
    map_configuration = Configuration.get_map_configuration!(id)
    version_id = map_configuration.version_id
    {:ok, _map_configuration} = Configuration.delete_map_configuration(map_configuration)

    conn
    |> put_flash(:info, "Map configuration deleted successfully.")
    |> redirect(to: ~p"/versions/#{version_id}/map_configurations")
  end

  def edit_obstacles(conn, %{"id" => id}) do
    map_configuration = Configuration.get_map_configuration!(id)
    changeset = Configuration.change_map_configuration(map_configuration)

    render(conn, :edit_obstacles,
      map_configuration: map_configuration,
      changeset: changeset,
      action: ~p"/versions/#{map_configuration.version_id}/map_configurations/#{map_configuration}/update_obstacles"
    )
  end

  def update_obstacles(conn, %{"id" => id, "map_configuration" => map_configuration_params}) do
    map_configuration = Configuration.get_map_configuration!(id)

    case Configuration.update_map_configuration(map_configuration, map_configuration_params) do
      {:ok, map_configuration} ->
        conn
        |> put_flash(:info, "Map configuration updated successfully.")
        |> redirect(to: ~p"/versions/#{map_configuration.version_id}/map_configurations/#{map_configuration}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit_obstacles,
          map_configuration: map_configuration,
          changeset: changeset,
          action: ~p"/versions/#{map_configuration.version_id}/map_configurations/#{map_configuration}/update_obstacles"
        )
    end
  end

  def edit_pools(conn, %{"id" => id}) do
    map_configuration = Configuration.get_map_configuration!(id)
    changeset = Configuration.change_map_configuration(map_configuration)

    render(conn, :edit_pools,
      map_configuration: map_configuration,
      changeset: changeset,
      action: ~p"/versions/#{map_configuration.version_id}/map_configurations/#{map_configuration}/update_pools"
    )
  end

  def update_pools(conn, %{"id" => id, "map_configuration" => map_configuration_params}) do
    map_configuration = Configuration.get_map_configuration!(id)

    case Configuration.update_map_configuration(map_configuration, map_configuration_params) do
      {:ok, map_configuration} ->
        conn
        |> put_flash(:info, "Map configuration updated successfully.")
        |> redirect(to: ~p"/versions/#{map_configuration.version_id}/map_configurations/#{map_configuration}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit_pools,
          map_configuration: map_configuration,
          changeset: changeset,
          action: ~p"/versions/#{map_configuration.version_id}/map_configurations/#{map_configuration}/update_obstacles"
        )
    end
  end

  def edit_crates(conn, %{"id" => id}) do
    map_configuration = Configuration.get_map_configuration!(id)
    changeset = Configuration.change_map_configuration(map_configuration)

    render(conn, :edit_crates,
      map_configuration: map_configuration,
      changeset: changeset,
      action: ~p"/versions/#{map_configuration.version_id}/map_configurations/#{map_configuration}/update_crates"
    )
  end

  def update_crates(conn, %{"id" => id, "map_configuration" => map_configuration_params}) do
    map_configuration = Configuration.get_map_configuration!(id)

    case Configuration.update_map_configuration(map_configuration, map_configuration_params) do
      {:ok, map_configuration} ->
        conn
        |> put_flash(:info, "Map configuration updated successfully.")
        |> redirect(to: ~p"/versions/#{map_configuration.version_id}/map_configurations/#{map_configuration}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit_crates,
          map_configuration: map_configuration,
          changeset: changeset,
          action: ~p"/versions/#{map_configuration.version_id}/map_configurations/#{map_configuration}/update_obstacles"
        )
    end
  end
end
