defmodule Configurator.Configure do
  @moduledoc """
  The Configure context.
  """

  import Ecto.Query, warn: false
  alias Configurator.Repo

  alias Configurator.Configure.Configuration

  @doc """
  Returns the list of configurations.

  ## Examples

      iex> list_configurations()
      [%Configuration{}, ...]

  """
  def list_configurations do
    Repo.all(Configuration)
  end

  @doc """
  Gets a single configuration.

  Raises `Ecto.NoResultsError` if the Configuration does not exist.

  ## Examples

      iex> get_configuration!(123)
      %Configuration{}

      iex> get_configuration!(456)
      ** (Ecto.NoResultsError)

  """
  def get_configuration!(id), do: Repo.get!(Configuration, id)

  @doc """
  Creates a configuration.

  ## Examples

      iex> create_configuration(%{field: value})
      {:ok, %Configuration{}}

      iex> create_configuration(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_configuration(attrs \\ %{}) do
    %Configuration{}
    |> Configuration.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a configuration.

  ## Examples

      iex> update_configuration(configuration, %{field: new_value})
      {:ok, %Configuration{}}

      iex> update_configuration(configuration, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_configuration(%Configuration{} = configuration, attrs) do
    configuration
    |> Configuration.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a configuration.

  ## Examples

      iex> delete_configuration(configuration)
      {:ok, %Configuration{}}

      iex> delete_configuration(configuration)
      {:error, %Ecto.Changeset{}}

  """
  def delete_configuration(%Configuration{} = configuration) do
    Repo.delete(configuration)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking configuration changes.

  ## Examples

      iex> change_configuration(configuration)
      %Ecto.Changeset{data: %Configuration{}}

  """
  def change_configuration(%Configuration{} = configuration, attrs \\ %{}) do
    Configuration.changeset(configuration, attrs)
  end
end
