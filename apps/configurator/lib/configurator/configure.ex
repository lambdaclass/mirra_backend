defmodule Configurator.Configure do
  @moduledoc """
  The Configure context.
  """

  import Ecto.Query, warn: false
  alias Configurator.Repo
  alias Configurator.Configure.Configuration
  alias Configurator.Configure.ConfigurationGroup
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
  Gets the current configuration in a configuration group.

  Returns nil if that configuration group doesn't have a current configuration

  ## Examples

      iex> get_current_configuration_in_group(configuration_group_id)
      %Configuration{configuration_group_id: configuration_group_id}

      iex> get_current_configuration_in_group(invalid_configuration_group_id)
      nil
  """

  def get_current_configuration_in_group(configuration_group_id) do
    q = from c in Configuration, where: c.configuration_group_id == ^configuration_group_id and c.current
    Repo.one(q)
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
  Updates a configuration.

  ## Examples

      iex> update_configuration(configuration, %{field: value})
      {:ok, %Configuration{}}

      iex> update_configuration(configuration, %{field: bad_value})
      {:error, %Ecto.Changeset{}}
  """
  def update_configuration(%Configuration{} = configuration, attrs \\ %{}) do
    configuration
    |> Configuration.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Changes the current default configuration to the one matching the given id.
  """
  def set_current_configuration(configuration_group_id, configuration_id) do
    current = get_current_configuration_in_group(configuration_group_id)
    new_current = get_configuration!(configuration_id)

    maybe_unset_current_configuration(current, new_current)
  end

  @doc """
  Gets a single configuration group.

  Raises `Ecto.NoResultsError` if the ConfigurationGroup does not exist.

  ## Examples

      iex> get_configuration_group!(123)
      %ConfigurationGroup{}

      iex> get_configuration_group!(456)
      ** (Ecto.NoResultsError)

  """
  def get_configuration_group!(id), do: Repo.get!(ConfigurationGroup, id)

  @doc """
  Returns the list of configurations groups by game.

  ## Examples

      iex> list_configurations(game_id)
      [%Configuration{}, ...]
  """
  def list_configuration_groups_by_game_id(game_id) do
    from(c in ConfigurationGroup, where: c.game_id == ^game_id)
    |> Repo.all()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking configuration group changes.

  ## Examples

      iex> change_configuration_group(configuration group)
      %Ecto.Changeset{data: %ConfigurationGroup{}}
  """
  def change_configuration_group(%ConfigurationGroup{} = configuration_group, attrs \\ %{}) do
    ConfigurationGroup.changeset(configuration_group, attrs)
  end

  @doc """
  Creates a configuration group.

  ## Examples

      iex> create_configuration_group(%{field: value})
      {:ok, %ConfigurationGroup{}}

      iex> create_configuration_group(%{field: bad_value})
      {:error, %Ecto.Changeset{}}
  """
  def create_configuration_group(attrs \\ %{}) do
    %ConfigurationGroup{}
    |> ConfigurationGroup.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns the list of configurations by group.

  ## Examples
      iex> list_configurations(group_id)
      [%Configuration{}, ...]

  """
  def list_configurations_by_group_id(group_id) do
    from(c in Configuration, where: c.configuration_group_id == ^group_id)
    |> Repo.all()
  end

  ########## Private functions ##########
  defp maybe_unset_current_configuration(nil = _configuration, configuration) do
    update_configuration(configuration, %{current: true})
  end

  defp maybe_unset_current_configuration(current_configuration, new_configuration) do
    Multi.new()
    |> Multi.update(
      :unset_current,
      Configuration.changeset(current_configuration, %{current: false})
    )
    |> Multi.update(
      :set_current,
      Configuration.changeset(new_configuration, %{current: true})
    )
    |> Repo.transaction()
  end
end
