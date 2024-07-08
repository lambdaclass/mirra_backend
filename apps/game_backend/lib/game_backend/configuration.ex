defmodule GameBackend.Configuration do
  @moduledoc """
  The Configuration context.
  """

  import Ecto.Query, warn: false
  alias GameBackend.Repo

  alias GameBackend.CurseOfMirra.MapConfiguration

  @doc """
  Returns the list of map_configurations.

  ## Examples

      iex> list_map_configurations()
      [%MapConfiguration{}, ...]

  """
  def list_map_configurations do
    Repo.all(MapConfiguration)
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
end
