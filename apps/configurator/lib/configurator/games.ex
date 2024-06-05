defmodule Configurator.Games do
  @moduledoc """
  The Games context.
  """
  alias Configurator.Repo

  alias Configurator.Games.Game

  @doc """
  Return the list of games.

  ## Examples
        iex> list_games()
        [%Game{}, ...]
  """
  def list_games do
    Repo.all(Game)
  end

  @doc """
  Gets a single game.

  Raises `Ecto.NoResultsError` if the Game does not exist.

  ## Examples
        iex> get_game!(123)
        %Game{}

        iex> get_game!(456)
        ** (Ecto.NoResultsError)
  """
  def get_game!(id), do: Repo.get!(Game, id)

  @doc """
  Create a new game.

  ## Examples
        iex> create_game(%{field: value})
        {:ok, %Game{}}

        iex> create_game(%{field: value})
        {:error, %Ecto.Changeset{}}

  """
  def create_game(attrs \\ %{}) do
    %Game{}
    |> Game.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an %Ecto.Changeset{} for tracking game changes.

  ## Examples
        iex> change_game(%Game{}, %{field: value})
        %Ecto.Changeset{}
  """
  def change_configuration(%Game{} = game, attrs \\ %{}) do
    Game.changeset(game, attrs)
  end
end
