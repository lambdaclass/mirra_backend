defmodule GameBackend.Configuration do
  @moduledoc """
  Configuration context for GameBackend
  """
  import Ecto.Query
  alias Ecto.Multi

  alias GameBackend.Configuration.GameMode
  alias GameBackend.CurseOfMirra.GameConfiguration
  alias GameBackend.Items.ConsumableItem
  alias GameBackend.Units.Characters.Character
  alias GameBackend.CurseOfMirra.MapConfiguration
  alias GameBackend.ArenaServers.ArenaServer
  alias GameBackend.Configuration.Version
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
  Returns the list of arena_servers.

  ## Examples

      iex> list_arena_servers()
      [%ArenaServer{}, ...]

  """
  def list_arena_servers do
    Repo.all(ArenaServer)
  end

  @doc """
  Gets a single arena_server.

  Raises `Ecto.NoResultsError` if the Arena server does not exist.

  ## Examples

      iex> get_arena_server!(123)
      %ArenaServer{}

      iex> get_arena_server!(456)
      ** (Ecto.NoResultsError)

  """
  def get_arena_server!(id), do: Repo.get!(ArenaServer, id)

  @doc """
  Creates a arena_server.

  ## Examples

      iex> create_arena_server(%{field: value})
      {:ok, %ArenaServer{}}

      iex> create_arena_server(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_arena_server(attrs \\ %{}) do
    %ArenaServer{}
    |> ArenaServer.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns the list of versions.

  ## Examples

      iex> list_versions()
      [%Version{}, ...]

  """
  def list_versions do
    Repo.all(Version)
  end

  @doc """
  Gets a single version.

  Raises `Ecto.NoResultsError` if the Version does not exist.

  ## Examples

      iex> get_version!(123)
      %Version{}

      iex> get_version!(456)
      ** (Ecto.NoResultsError)

  """
  def get_version!(id), do: Repo.get!(Version, id)

  @doc """
  Creates a version.

  ## Examples

      iex> create_version(%{field: value})
      {:ok, %Version{}}

      iex> create_version(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_version(attrs \\ %{}) do
    %Version{}
    |> Version.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a arena_server.

  ## Examples

      iex> update_arena_server(arena_server, %{field: new_value})
      {:ok, %ArenaServer{}}

      iex> update_arena_server(arena_server, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_arena_server(%ArenaServer{} = arena_server, attrs) do
    arena_server
    |> ArenaServer.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates a version.

  ## Examples

      iex> update_version(version, %{field: new_value})
      {:ok, %Version{}}

      iex> update_version(version, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_version(%Version{} = version, attrs) do
    version
    |> Version.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a arena_server.

  ## Examples

      iex> delete_arena_server(arena_server)
      {:ok, %ArenaServer{}}

      iex> delete_arena_server(arena_server)
      {:error, %Ecto.Changeset{}}

  """
  def delete_arena_server(%ArenaServer{} = arena_server) do
    Repo.delete(arena_server)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking arena_server changes.

  ## Examples

      iex> change_arena_server(arena_server)
      %Ecto.Changeset{data: %ArenaServer{}}

  """
  def change_arena_server(%ArenaServer{} = arena_server, attrs \\ %{}) do
    ArenaServer.changeset(arena_server, attrs)
  end

  @doc """
  Deletes a version.

  ## Examples

      iex> delete_version(version)
      {:ok, %Version{}}

      iex> delete_version(version)
      {:error, %Ecto.Changeset{}}

  """
  def delete_version(%Version{} = version) do
    Repo.delete(version)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking version changes.

  ## Examples

      iex> change_version(version)
      %Ecto.Changeset{data: %Version{}}

  """
  def change_version(%Version{} = version, attrs \\ %{}) do
    Version.changeset(version, attrs)
  end

  @doc """
  Gets the latest version based on the current field flag

  ## Examples

      iex> get_current_version()
      %Version{}
  """

  def get_current_version do
    q =
      from(v in Version,
        where: v.current,
        preload: [
          :consumable_items,
          :skills,
          :map_configurations,
          :game_configuration,
          characters: [
            [basic_skill: [mechanics: [:on_arrival_mechanic, :on_explode_mechanics, :parent_mechanic]]],
            [ultimate_skill: [mechanics: [:on_arrival_mechanic, :on_explode_mechanics, :parent_mechanic]]],
            [dash_skill: [mechanics: [:on_arrival_mechanic, :on_explode_mechanics, :parent_mechanic]]]
          ]
        ]
      )

    Repo.one(q)
  end

  @doc """
  List all characters by version

  ## Examples
      iex> list_characters_by_version(version)
      [%Character{}, ...]
  """
  def list_characters_by_version(version) do
    curse_id = GameBackend.Utils.get_game_id(:curse_of_mirra)

    q =
      from(c in Character,
        where: ^curse_id == c.game_id and c.version_id == ^version.id,
        preload: [
          basic_skill: [mechanics: [:on_arrival_mechanic, :on_explode_mechanics, :parent_mechanic]],
          ultimate_skill: [mechanics: [:on_arrival_mechanic, :on_explode_mechanics, :parent_mechanic]],
          dash_skill: [mechanics: [:on_arrival_mechanic, :on_explode_mechanics, :parent_mechanic]]
        ]
      )

    Repo.all(q)
  end

  @doc """
  Get game configuration by version

  ## Examples
      iex> get_game_configuration_by_version(version)
      %GameConfiguration{}
  """
  def get_game_configuration_by_version(version) do
    q =
      from(g in GameConfiguration,
        where: g.version_id == ^version.id
      )

    Repo.one(q)
  end

  @doc """
  List all consumable items by version

  ## Examples
      iex> list_consumable_items_by_version(version)
      [%ConsumableItem{}, ...]
  """
  def list_consumable_items_by_version(version) do
    q = from(ci in ConsumableItem, where: ci.version_id == ^version.id and ci.active)
    Repo.all(q)
  end

  @doc """

  """
  def list_map_configurations_by_version(version) do
    q = from(m in MapConfiguration, where: m.version_id == ^version.id)
    Repo.all(q)
  end

  @doc """
  Marks a version as current and the former one as not current

  ## Examples
      iex> mark_as_current_version(version)
      {:ok, %Version{}}
  """
  def mark_as_current_version(version) do
    former_version = get_current_version()

    Multi.new()
    |> Multi.run(:different_versions, fn _repo, _changes_so_far ->
      if version.id == former_version.id do
        {:error, "Version is already current one"}
      else
        {:ok, version}
      end
    end)
    |> Multi.run(:update_previous_version, fn _, _ ->
      if former_version do
        Ecto.Changeset.change(former_version, %{current: false})
        |> Repo.update()
      else
        {:ok, :no_former_version}
      end
    end)
    |> Multi.update(:version, Ecto.Changeset.change(version, %{current: true}))
    |> Repo.transaction()
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
  Returns the list of game_modes.

  ## Examples

      iex> list_game_modes()
      [%GameMode{}, ...]

  """
  def list_game_modes do
    Repo.all(GameMode)
  end

  @doc """
  Gets a single game_mode.

  Raises `Ecto.NoResultsError` if the Game mode does not exist.

  ## Examples

      iex> get_game_mode!(123)
      %GameMode{}

      iex> get_game_mode!(456)
      ** (Ecto.NoResultsError)

  """
  def get_game_mode!(id), do: Repo.get!(GameMode, id)

  @doc """
  Creates a game_mode.

  ## Examples

      iex> create_game_mode(%{field: value})
      {:ok, %GameMode{}}

      iex> create_game_mode(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_game_mode(attrs \\ %{}) do
    %GameMode{}
    |> GameMode.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a game_mode.

  ## Examples

      iex> update_game_mode(game_mode, %{field: new_value})
      {:ok, %GameMode{}}

      iex> update_game_mode(game_mode, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_game_mode(%GameMode{} = game_mode, attrs) do
    game_mode
    |> GameMode.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a game_mode.

  ## Examples

      iex> delete_game_mode(game_mode)
      {:ok, %GameMode{}}

      iex> delete_game_mode(game_mode)
      {:error, %Ecto.Changeset{}}

  """
  def delete_game_mode(%GameMode{} = game_mode) do
    Repo.delete(game_mode)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking game_mode changes.

  ## Examples

      iex> change_game_mode(game_mode)
      %Ecto.Changeset{data: %GameMode{}}

  """
  def change_game_mode(%GameMode{} = game_mode, attrs \\ %{}) do
    GameMode.changeset(game_mode, attrs)
  end
end
