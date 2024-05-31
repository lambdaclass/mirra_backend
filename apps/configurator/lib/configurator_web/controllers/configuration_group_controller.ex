defmodule ConfiguratorWeb.ConfigurationGroupController do
  @moduledoc """
  The ConfigurationGroup controller.
  """
  use ConfiguratorWeb, :controller

  alias Configurator.Configure.ConfigurationGroup
  alias Configurator.Configure
  alias Configurator.Games

  def index(conn, %{"game_id" => game_id}) do
    game = Games.get_game!(game_id)
    configuration_groups = Configure.list_configuration_groups_by_game_id(game_id)
    render(conn, :index, configuration_groups: configuration_groups, game: game)
  end

  def new(conn, %{"game_id" => game_id}) do
    game = Games.get_game!(game_id)
    changeset = Configure.change_configuration_group(%ConfigurationGroup{})
    render(conn, :new, changeset: changeset, game: game)
  end

  def create(conn, %{"configuration_group" => game_params, "game_id" => game_id}) do
    game = Games.get_game!(game_id)

    case Configure.create_configuration_group(game_params) do
      {:ok, configuration_group} ->
        conn
        |> put_flash(:info, "Configuration Group created successfully.")
        |> redirect(to: ~p"/games/#{game}/configuration_groups/#{configuration_group}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"game_id" => game_id, "id" => id}) do
    game = Games.get_game!(id)
    configuration_group = Configure.get_configuration_group!(id)
    configurations = Configure.list_configurations_by_group_id(id)
    render(conn, :show, game: game, configurations: configurations, configuration_group: configuration_group)
  end
end
