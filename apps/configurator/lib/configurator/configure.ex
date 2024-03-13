defmodule Configurator.Configure do
  @moduledoc """
  The Configure context.
  """

  import Ecto.Query, warn: false
  alias Configurator.Repo
  alias Configurator.Configure.Configuration
  alias Ecto.Multi

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
  Gets the default configuration.

  Raises `Ecto.NoResultsError` if no default Configuration exists.

  ## Examples

      iex> get_default_configuration!()
      %Configuration{}

      iex> get_default_configuration!()
      ** (Ecto.NoResultsError)
  """

  def get_default_configuration!() do
    from(c in Configuration, where: c.is_default == true)
    |> Repo.one!()
  end

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
  Returns an `%Ecto.Changeset{}` for tracking configuration changes.

  ## Examples

      iex> change_configuration(configuration)
      %Ecto.Changeset{data: %Configuration{}}

  """
  def change_configuration(%Configuration{} = configuration, attrs \\ %{}) do
    Configuration.changeset(configuration, attrs)
  end

  @doc """
  Changes the current default configuration to the one matching the given id.
  """
  def set_default_configuration(id) do
    default_config = get_default_configuration!()
    new_default_config = get_configuration!(id)

    Multi.new()
    |> Multi.update(
      :unset_default_config,
      Configuration.changeset(default_config, %{is_default: false})
    )
    |> Multi.update(
      :set_default_config,
      Configuration.changeset(new_default_config, %{is_default: true})
    )
    |> Repo.transaction()
  end
end
