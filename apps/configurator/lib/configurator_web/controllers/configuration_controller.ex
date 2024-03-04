defmodule ConfiguratorWeb.ConfigurationController do
  use ConfiguratorWeb, :controller

  alias Configurator.Configure
  alias Configurator.Configure.Configuration

  def index(conn, _params) do
    configurations = Configure.list_configurations()
    render(conn, :index, configurations: configurations)
  end

  def new(conn, _params) do
    changeset = Configure.change_configuration(%Configuration{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"configuration" => configuration_params}) do
    case Configure.create_configuration(configuration_params) do
      {:ok, configuration} ->
        conn
        |> put_flash(:info, "Configuration created successfully.")
        |> redirect(to: ~p"/configurations/#{configuration}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    configuration = Configure.get_configuration!(id)
    render(conn, :show, configuration: configuration)
  end

  def edit(conn, %{"id" => id}) do
    configuration = Configure.get_configuration!(id)
    changeset = Configure.change_configuration(configuration)
    render(conn, :edit, configuration: configuration, changeset: changeset)
  end

  def update(conn, %{"id" => id, "configuration" => configuration_params}) do
    configuration = Configure.get_configuration!(id)

    case Configure.update_configuration(configuration, configuration_params) do
      {:ok, configuration} ->
        conn
        |> put_flash(:info, "Configuration updated successfully.")
        |> redirect(to: ~p"/configurations/#{configuration}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, configuration: configuration, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    configuration = Configure.get_configuration!(id)
    {:ok, _configuration} = Configure.delete_configuration(configuration)

    conn
    |> put_flash(:info, "Configuration deleted successfully.")
    |> redirect(to: ~p"/configurations")
  end
end
