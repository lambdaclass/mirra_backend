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

  def edit(conn, %{"game_id" => game_id, "configuration_group_id" => configuration_group_id, "id" => id}) do
    game = Games.get_game!(game_id)
    configuration_group = Configure.get_configuration_group!(configuration_group_id)
    configuration = Configure.get_configuration!(id)
    render(conn, :edit, configuration: configuration, configuration_group: configuration_group, game: game)
  end

  def show(conn, %{"game_id" => game_id, "configuration_group_id" => configuration_group_id, "id" => id}) do
    game = Games.get_game!(game_id)
    configuration_group = Configure.get_configuration_group!(configuration_group_id)
    configuration = Configure.get_configuration!(id)
    render(conn, :show, configuration: configuration, configuration_group: configuration_group, game: game)
  end
end
