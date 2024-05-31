defmodule ConfiguratorWeb.ConfigurationController do
  use ConfiguratorWeb, :controller

  alias Configurator.Configure
  alias Configurator.Configure.Configuration
  alias Configurator.Games

  def index(conn, _params) do
    configurations = Configure.list_configurations()
    render(conn, :index, configurations: configurations)
  end

  def new(conn, %{"game_id" => id}) do
    game = Games.get_game!(id)
    changeset = Configuration.changeset(%Configuration{}, %{game_id: id})
    render(conn, :new, changeset: changeset, game: game)
  end

  def create(conn, %{"configuration" => configuration_params, "game_id" => game_id}) do
    case Configure.create_configuration(configuration_params) do
      {:ok, configuration} ->
        conn
        |> put_flash(:info, "Configuration created successfully.")
        |> redirect(to: ~p"/configurations/#{configuration}")

      {:error, %Ecto.Changeset{} = changeset} ->
        game = Games.get_game!(game_id)
        render(conn, :new, changeset: changeset, game: game)
    end
  end

  def show(conn, %{"id" => id}) do
    configuration = Configure.get_configuration!(id)
    render(conn, :show, configuration: configuration)
  end

  def show(conn, _) do
    configuration = Configure.get_default_configuration!()
    render(conn, :show, configuration: configuration)
  end

  def set_default(conn, %{"id" => id}) do
    case Configure.set_default_configuration(id) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Default configuration set successfully.")
        |> redirect(to: ~p"/configurations/#{id}")

      {:error, _} ->
        conn
        |> put_flash(:error, "Failed to set default configuration.")
        |> redirect(to: ~p"/configurations/#{id}")
    end
  end
end
