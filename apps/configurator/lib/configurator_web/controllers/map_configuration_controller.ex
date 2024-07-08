defmodule ConfiguratorWeb.MapConfigurationController do
  use ConfiguratorWeb, :controller

  alias GameBackend.Configuration
  alias GameBackend.CurseOfMirra.MapConfiguration

  def index(conn, _params) do
    map_configurations = Configuration.list_map_configurations()
    render(conn, :index, map_configurations: map_configurations)
  end

  def new(conn, _params) do
    changeset = Configuration.change_map_configuration(%MapConfiguration{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"map_configuration" => map_configuration_params}) do
    case Configuration.create_map_configuration(map_configuration_params) do
      {:ok, map_configuration} ->
        conn
        |> put_flash(:info, "Map configuration created successfully.")
        |> redirect(to: ~p"/map_configurations/#{map_configuration}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    map_configuration = Configuration.get_map_configuration!(id)
    render(conn, :show, map_configuration: map_configuration)
  end

  def edit(conn, %{"id" => id}) do
    map_configuration = Configuration.get_map_configuration!(id)
    changeset = Configuration.change_map_configuration(map_configuration)
    render(conn, :edit, map_configuration: map_configuration, changeset: changeset)
  end

  def update(conn, %{"id" => id, "map_configuration" => map_configuration_params}) do
    map_configuration = Configuration.get_map_configuration!(id)

    case Configuration.update_map_configuration(map_configuration, map_configuration_params) do
      {:ok, map_configuration} ->
        conn
        |> put_flash(:info, "Map configuration updated successfully.")
        |> redirect(to: ~p"/map_configurations/#{map_configuration}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, map_configuration: map_configuration, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    map_configuration = Configuration.get_map_configuration!(id)
    {:ok, _map_configuration} = Configuration.delete_map_configuration(map_configuration)

    conn
    |> put_flash(:info, "Map configuration deleted successfully.")
    |> redirect(to: ~p"/map_configurations")
  end
end
