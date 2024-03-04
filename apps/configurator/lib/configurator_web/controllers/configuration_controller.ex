defmodule ConfiguratorWeb.ConfigurationController do
  use ConfiguratorWeb, :controller

  alias Configurator.Configure
  alias Configurator.Configure.Configuration

  def index(conn, _params) do
    configurations = Configure.list_configurations()
    render(conn, :index, configurations: configurations)
  end

  def new(conn, params) do
    config =
      case params["id"] do
        nil -> Configure.get_default_configuration!()
        id -> Configure.get_configuration!(id)
      end

    changeset = Configure.change_configuration(%Configuration{data: config.data})
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
end
