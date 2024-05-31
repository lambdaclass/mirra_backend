defmodule ConfiguratorWeb.GameController do
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
    configurations = Configure.list_all_configurations_by_game(game.id)
    render(conn, :show, game: game, configurations: configurations)
  end
end
