defmodule Configurator.Configuration do
  @moduledoc """
  The Configuration context.
  """

  import Ecto.Query, warn: false
  alias Configurator.Repo

  alias Configurator.Configuration.Character

  @doc """
  Returns the list of characters.

  ## Examples

      iex> list_characters()
      [%Character{}, ...]

  """
  def list_characters do
    Repo.all(Character)
  end

  @doc """
  Gets a single character.

  Raises `Ecto.NoResultsError` if the Character does not exist.

  ## Examples

      iex> get_character!(123)
      %Character{}

      iex> get_character!(456)
      ** (Ecto.NoResultsError)

  """
  def get_character!(id), do: Repo.get!(Character, id)

  @doc """
  Creates a character.

  ## Examples

      iex> create_character(%{field: value})
      {:ok, %Character{}}

      iex> create_character(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_character(attrs \\ %{}) do
    %Character{}
    |> Character.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a character.

  ## Examples

      iex> update_character(character, %{field: new_value})
      {:ok, %Character{}}

      iex> update_character(character, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_character(%Character{} = character, attrs) do
    character
    |> Character.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a character.

  ## Examples

      iex> delete_character(character)
      {:ok, %Character{}}

      iex> delete_character(character)
      {:error, %Ecto.Changeset{}}

  """
  def delete_character(%Character{} = character) do
    Repo.delete(character)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking character changes.

  ## Examples

      iex> change_character(character)
      %Ecto.Changeset{data: %Character{}}

  """
  def change_character(%Character{} = character, attrs \\ %{}) do
    Character.changeset(character, attrs)
  end

  alias Configurator.Configuration.GameConfig

  @doc """
  Returns the list of game_configurations.

  ## Examples

      iex> list_game_configurations()
      [%GameConfig{}, ...]

  """
  def list_game_configurations do
    Repo.all(GameConfig)
  end

  @doc """
  Gets a single game_config.

  Raises `Ecto.NoResultsError` if the Game config does not exist.

  ## Examples

      iex> get_game_config!(123)
      %GameConfig{}

      iex> get_game_config!(456)
      ** (Ecto.NoResultsError)

  """
  def get_game_config!(id), do: Repo.get!(GameConfig, id)

  @doc """
  Creates a game_config.

  ## Examples

      iex> create_game_config(%{field: value})
      {:ok, %GameConfig{}}

      iex> create_game_config(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_game_config(attrs \\ %{}) do
    %GameConfig{}
    |> GameConfig.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a game_config.

  ## Examples

      iex> update_game_config(game_config, %{field: new_value})
      {:ok, %GameConfig{}}

      iex> update_game_config(game_config, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_game_config(%GameConfig{} = game_config, attrs) do
    game_config
    |> GameConfig.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a game_config.

  ## Examples

      iex> delete_game_config(game_config)
      {:ok, %GameConfig{}}

      iex> delete_game_config(game_config)
      {:error, %Ecto.Changeset{}}

  """
  def delete_game_config(%GameConfig{} = game_config) do
    Repo.delete(game_config)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking game_config changes.

  ## Examples

      iex> change_game_config(game_config)
      %Ecto.Changeset{data: %GameConfig{}}

  """
  def change_game_config(%GameConfig{} = game_config, attrs \\ %{}) do
    GameConfig.changeset(game_config, attrs)
  end
end
