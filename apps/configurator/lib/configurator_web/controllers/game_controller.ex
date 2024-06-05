defmodule ConfiguratorWeb.GameController do
  @moduledoc """
  The Game controller.
  """
  use ConfiguratorWeb, :controller

  alias Configurator.Games
  alias Configurator.Games.Game
  alias Configurator.Configure

  def index(conn, _params) do
    games = Configurator.Games.list_games()
    render(conn, :index, games: games)
  end

  def new(conn, _params) do
    changeset = Games.change_configuration(%Game{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"game" => game_params}) do
    case Games.create_game(game_params) do
      {:ok, game} ->
        conn
        |> put_flash(:info, "Game created successfully.")
        |> redirect(to: ~p"/games/#{game}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    game = Games.get_game!(id)
    configuration_groups = Configure.list_configuration_groups_by_game_id(game.id)
    render(conn, :show, game: game, configuration_groups: configuration_groups)
  end
end
