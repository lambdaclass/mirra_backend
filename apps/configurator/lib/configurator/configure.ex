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
  Gets the default configuration.

  Raises `Ecto.NoResultsError` if no default Configuration exists.

  ## Examples

      iex> get_default_configuration!()
      %Configuration{}

      iex> get_default_configuration!()
      ** (Ecto.NoResultsError)
  """

  def get_default_configuration!() do
    config =
      from(c in Configuration, where: c.current)
      |> Repo.one()

    case config do
      nil -> seed_default_configuration!()
      config -> config
    end
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
      Configuration.changeset(default_config, %{current: false})
    )
    |> Multi.update(
      :set_default_config,
      Configuration.changeset(new_default_config, %{current: true})
    )
    |> Repo.transaction()
  end

  defp seed_default_configuration!() do
    data_json = File.read!(Application.app_dir(:configurator, "priv/config.json"))

    %Configurator.Configure.Configuration{}
    |> Configuration.changeset(%{data: data_json, current: true})
    |> Repo.insert!()
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
end
