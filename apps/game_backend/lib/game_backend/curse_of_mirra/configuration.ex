defmodule GameBackend.CurseOfMirra.Configuration do
  @moduledoc """
  The CurseOfMirra.Configuration context.
  """

  import Ecto.Query, warn: false
  alias GameBackend.Repo

  alias GameBackend.CurseOfMirra.Configuration.Mechanic

  @doc """
  Returns the list of mechanics.

  ## Examples

      iex> list_mechanics()
      [%Mechanic{}, ...]

  """
  def list_mechanics do
    Repo.all(Mechanic)
  end

  @doc """
  Gets a single mechanic.

  Raises `Ecto.NoResultsError` if the Mechanic does not exist.

  ## Examples

      iex> get_mechanic!(123)
      %Mechanic{}

      iex> get_mechanic!(456)
      ** (Ecto.NoResultsError)

  """
  def get_mechanic!(id), do: Repo.get!(Mechanic, id)

  @doc """
  Creates a mechanic.

  ## Examples

      iex> create_mechanic(%{field: value})
      {:ok, %Mechanic{}}

      iex> create_mechanic(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_mechanic(attrs \\ %{}) do
    %Mechanic{}
    |> Mechanic.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a mechanic.

  ## Examples

      iex> update_mechanic(mechanic, %{field: new_value})
      {:ok, %Mechanic{}}

      iex> update_mechanic(mechanic, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_mechanic(%Mechanic{} = mechanic, attrs) do
    mechanic
    |> Mechanic.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a mechanic.

  ## Examples

      iex> delete_mechanic(mechanic)
      {:ok, %Mechanic{}}

      iex> delete_mechanic(mechanic)
      {:error, %Ecto.Changeset{}}

  """
  def delete_mechanic(%Mechanic{} = mechanic) do
    Repo.delete(mechanic)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking mechanic changes.

  ## Examples

      iex> change_mechanic(mechanic)
      %Ecto.Changeset{data: %Mechanic{}}

  """
  def change_mechanic(%Mechanic{} = mechanic, attrs \\ %{}) do
    Mechanic.changeset(mechanic, attrs)
  end
end
