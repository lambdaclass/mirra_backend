defmodule GameBackend.Configuration do
  @moduledoc """
  Configuration context for GameBackend
  """
  import Ecto.Query
  alias GameBackend.CurseOfMirra.GameConfiguration
  alias GameBackend.CurseOfMirra.MapConfiguration
  alias GameBackend.Repo

  @doc """
  Returns the list of game_configurations.

  ## Examples

      iex> list_game_configurations()
      [%GameConfiguration{}, ...]

  """
  def list_game_configurations do
    Repo.all(GameConfiguration)
  end

  @doc """
  Gets a single game_configuration.

  Raises `Ecto.NoResultsError` if the Game configuration does not exist.

  ## Examples

      iex> get_game_configuration!(123)
      %GameConfiguration{}

      iex> get_game_configuration!(456)
      ** (Ecto.NoResultsError)

  """
  def get_game_configuration!(id), do: Repo.get!(GameConfiguration, id)

  @doc """
  Creates a game_configuration.

  ## Examples

      iex> create_game_configuration(%{field: value})
      {:ok, %GameConfiguration{}}

      iex> create_game_configuration(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_game_configuration(attrs \\ %{}) do
    %GameConfiguration{}
    |> GameConfiguration.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a game_configuration.

  ## Examples

      iex> update_game_configuration(game_configuration, %{field: new_value})
      {:ok, %GameConfiguration{}}

      iex> update_game_configuration(game_configuration, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_game_configuration(%GameConfiguration{} = game_configuration, attrs) do
    game_configuration
    |> GameConfiguration.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a game_configuration.

  ## Examples

      iex> delete_game_configuration(game_configuration)
      {:ok, %GameConfiguration{}}

      iex> delete_game_configuration(game_configuration)
      {:error, %Ecto.Changeset{}}

  """
  def delete_game_configuration(%GameConfiguration{} = game_configuration) do
    Repo.delete(game_configuration)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking game_configuration changes.

  ## Examples

      iex> change_game_configuration(game_configuration)
      %Ecto.Changeset{data: %GameConfiguration{}}

  """
  def change_game_configuration(%GameConfiguration{} = game_configuration, attrs \\ %{}) do
    GameConfiguration.changeset(game_configuration, attrs)
  end

  @doc """
  Gets the latest game configuration

  ## Examples

      iex> get_latest_game_configuration()
      %GameConfiguration{}
  """
  def get_latest_game_configuration do
    Repo.one(from(g in GameConfiguration, order_by: [desc: g.inserted_at], limit: 1))
  end

  @doc """
  Returns the list of map_configurations.

  ## Examples

      iex> list_map_configurations()
      [%MapConfiguration{}, ...]

  """
  def list_map_configurations do
    Repo.all(from(m in MapConfiguration, order_by: [desc: m.inserted_at]))
  end

  @doc """
  Gets a single map_configuration.

  Raises `Ecto.NoResultsError` if the Map configuration does not exist.

  ## Examples

      iex> get_map_configuration!(123)
      %MapConfiguration{}

      iex> get_map_configuration!(456)
      ** (Ecto.NoResultsError)

  """
  def get_map_configuration!(id), do: Repo.get!(MapConfiguration, id)

  @doc """
  Creates a map_configuration.

  ## Examples

      iex> create_map_configuration(%{field: value})
      {:ok, %MapConfiguration{}}

      iex> create_map_configuration(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_map_configuration(attrs \\ %{}) do
    %MapConfiguration{}
    |> MapConfiguration.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a map_configuration.

  ## Examples

      iex> update_map_configuration(map_configuration, %{field: new_value})
      {:ok, %MapConfiguration{}}

      iex> update_map_configuration(map_configuration, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_map_configuration(%MapConfiguration{} = map_configuration, attrs) do
    map_configuration
    |> MapConfiguration.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a map_configuration.

  ## Examples

      iex> delete_map_configuration(map_configuration)
      {:ok, %MapConfiguration{}}

      iex> delete_map_configuration(map_configuration)
      {:error, %Ecto.Changeset{}}

  """
  def delete_map_configuration(%MapConfiguration{} = map_configuration) do
    Repo.delete(map_configuration)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking map_configuration changes.

  ## Examples

      iex> change_map_configuration(map_configuration)
      %Ecto.Changeset{data: %MapConfiguration{}}

  """
  def change_map_configuration(%MapConfiguration{} = map_configuration, attrs \\ %{}) do
    MapConfiguration.changeset(map_configuration, attrs)
  end

  @doc """
  Gets the latest map configuration
  ## Examples
      iex> get_latest_map_configuration()
      %MapConfiguration{}
  """
  def get_latest_map_configuration do
    Repo.one(from(m in MapConfiguration, order_by: [desc: m.inserted_at], limit: 1))
  end
end
