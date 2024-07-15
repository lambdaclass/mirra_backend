defmodule GameBackend.CurseOfMirra.Effects do
  @moduledoc """
  Module in charge of configuration effects related things
  """
  alias GameBackend.Repo
  alias GameBackend.Effects.ConfigurationEffect

  @doc """
  Returns the list of configuration_effects.

  ## Examples

      iex> list_configuration_effects()
      [%ConfigurationEffect{}, ...]

  """
  def list_configuration_effects do
    Repo.all(ConfigurationEffect)
  end

  @doc """
  Gets a single configuration_effect.

  Raises `Ecto.NoResultsError` if the Configuration effect does not exist.

  ## Examples

      iex> get_configuration_effect!(123)
      %ConfigurationEffect{}

      iex> get_configuration_effect!(456)
      ** (Ecto.NoResultsError)

  """
  def get_configuration_effect!(id), do: Repo.get!(ConfigurationEffect, id)

  @doc """
  Creates a configuration_effect.

  ## Examples

      iex> create_configuration_effect(%{field: value})
      {:ok, %ConfigurationEffect{}}

      iex> create_configuration_effect(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_configuration_effect(attrs \\ %{}) do
    %ConfigurationEffect{}
    |> ConfigurationEffect.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a configuration_effect.

  ## Examples

      iex> update_configuration_effect(configuration_effect, %{field: new_value})
      {:ok, %ConfigurationEffect{}}

      iex> update_configuration_effect(configuration_effect, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_configuration_effect(%ConfigurationEffect{} = configuration_effect, attrs) do
    configuration_effect
    |> ConfigurationEffect.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a configuration_effect.

  ## Examples

      iex> delete_configuration_effect(configuration_effect)
      {:ok, %ConfigurationEffect{}}

      iex> delete_configuration_effect(configuration_effect)
      {:error, %Ecto.Changeset{}}

  """
  def delete_configuration_effect(%ConfigurationEffect{} = configuration_effect) do
    Repo.delete(configuration_effect)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking configuration_effect changes.

  ## Examples

      iex> change_configuration_effect(configuration_effect)
      %Ecto.Changeset{data: %ConfigurationEffect{}}

  """
  def change_configuration_effect(%ConfigurationEffect{} = configuration_effect, attrs \\ %{}) do
    ConfigurationEffect.changeset(configuration_effect, attrs)
  end
end
