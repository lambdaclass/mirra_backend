defmodule ConfiguratorWeb.ConfigurationController do
  use ConfiguratorWeb, :controller

  alias Configurator.Configure
  alias Configurator.Configure.Configuration
  alias Configurator.Games

  def new(conn, %{"configuration_group_id" => configuration_group_id, "game_id" => game_id}) do
    game = Games.get_game!(game_id)
    configuration_group = Configure.get_configuration_group!(configuration_group_id)
    changeset = Configuration.changeset(%Configuration{}, %{configuration_group_id: configuration_group_id})
    render(conn, :new, changeset: changeset, configuration_group: configuration_group, game: game)
  end

  def create(conn, %{
        "configuration" => configuration_params,
        "game_id" => game_id,
        "configuration_group_id" => configuration_group_id
      }) do
    game = Games.get_game!(game_id)
    configuration_group = Configure.get_configuration_group!(configuration_group_id)

    case Configure.create_configuration(configuration_params) do
      {:ok, _configuration} ->
        conn
        |> put_flash(:info, "Configuration created successfully.")
        |> redirect(to: ~p"/games/#{game}/configuration_groups/#{configuration_group}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset, configuration_group: configuration_group, game: game)
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
