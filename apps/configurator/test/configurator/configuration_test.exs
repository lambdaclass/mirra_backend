defmodule Configurator.ConfigurationTest do
  use Configurator.DataCase

  alias GameBackend.Configuration

  describe "map_configurations" do
    alias GameBackend.CurseOfMirra.MapConfiguration

    import Configurator.ConfigurationFixtures

    @invalid_attrs %{radius: nil, initial_positions: nil, obstacles: nil, bushes: nil}

    test "get_map_configuration!/1 returns the map_configuration with given id" do
      map_configuration = map_configuration_fixture()
      assert Configuration.get_map_configuration!(map_configuration.id) == map_configuration
    end

    test "create_map_configuration/1 with valid data creates a map_configuration" do
      version = version_fixture()
      valid_attrs = %{radius: "120.5", initial_positions: [], obstacles: [], bushes: [], version_id: version.id}

      assert {:ok, %MapConfiguration{} = map_configuration} = Configuration.create_map_configuration(valid_attrs)
      assert map_configuration.radius == Decimal.new("120.5")
      assert map_configuration.initial_positions == []
      assert map_configuration.obstacles == []
      assert map_configuration.bushes == []
    end

    test "create_map_configuration/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Configuration.create_map_configuration(@invalid_attrs)
    end

    test "update_map_configuration/2 with valid data updates the map_configuration" do
      map_configuration = map_configuration_fixture()
      update_attrs = %{radius: "456.7", initial_positions: [], obstacles: [], bushes: []}

      assert {:ok, %MapConfiguration{} = map_configuration} =
               Configuration.update_map_configuration(map_configuration, update_attrs)

      assert map_configuration.radius == Decimal.new("456.7")
      assert map_configuration.initial_positions == []
      assert map_configuration.obstacles == []
      assert map_configuration.bushes == []
    end

    test "update_map_configuration/2 with invalid data returns error changeset" do
      map_configuration = map_configuration_fixture()
      assert {:error, %Ecto.Changeset{}} = Configuration.update_map_configuration(map_configuration, @invalid_attrs)
      assert map_configuration == Configuration.get_map_configuration!(map_configuration.id)
    end

    test "delete_map_configuration/1 deletes the map_configuration" do
      map_configuration = map_configuration_fixture()
      assert {:ok, %MapConfiguration{}} = Configuration.delete_map_configuration(map_configuration)
      assert_raise Ecto.NoResultsError, fn -> Configuration.get_map_configuration!(map_configuration.id) end
    end

    test "change_map_configuration/1 returns a map_configuration changeset" do
      map_configuration = map_configuration_fixture()
      assert %Ecto.Changeset{} = Configuration.change_map_configuration(map_configuration)
    end
  end

  describe "arena_servers" do
    alias GameBackend.ArenaServers.ArenaServer

    import Configurator.ConfigurationFixtures

    @invalid_attrs %{name: nil, ip: nil, url: nil, status: nil, environment: nil}

    test "get_arena_server!/1 returns the arena_server with given id" do
      arena_server = arena_server_fixture()
      assert Configuration.get_arena_server!(arena_server.id) == arena_server
    end

    test "create_arena_server/1 with valid data creates a arena_server" do
      valid_attrs = %{name: "some name", ip: "some ip", url: "some url", status: :active, environment: :production}

      assert {:ok, %ArenaServer{} = arena_server} = Configuration.create_arena_server(valid_attrs)
      assert arena_server.name == "some name"
      assert arena_server.ip == "some ip"
      assert arena_server.url == "some url"
      assert arena_server.status == :active
      assert arena_server.environment == :production
    end

    test "create_arena_server/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Configuration.create_arena_server(@invalid_attrs)
    end

    test "update_arena_server/2 with valid data updates the arena_server" do
      arena_server = arena_server_fixture()

      update_attrs = %{
        name: "some updated name",
        ip: "some updated ip",
        url: "some updated url",
        status: :inactive,
        environment: :development
      }

      assert {:ok, %ArenaServer{} = arena_server} = Configuration.update_arena_server(arena_server, update_attrs)
      assert arena_server.name == "some updated name"
      assert arena_server.ip == "some updated ip"
      assert arena_server.url == "some updated url"
      assert arena_server.status == :inactive
      assert arena_server.environment == :development
    end

    test "update_arena_server/2 with invalid data returns error changeset" do
      arena_server = arena_server_fixture()
      assert {:error, %Ecto.Changeset{}} = Configuration.update_arena_server(arena_server, @invalid_attrs)
      assert arena_server == Configuration.get_arena_server!(arena_server.id)
    end

    test "delete_arena_server/1 deletes the arena_server" do
      arena_server = arena_server_fixture()
      assert {:ok, %ArenaServer{}} = Configuration.delete_arena_server(arena_server)
      assert_raise Ecto.NoResultsError, fn -> Configuration.get_arena_server!(arena_server.id) end
    end

    test "change_arena_server/1 returns a arena_server changeset" do
      arena_server = arena_server_fixture()
      assert %Ecto.Changeset{} = Configuration.change_arena_server(arena_server)
    end
  end

  describe "versions" do
    alias GameBackend.Configuration.Version

    import Configurator.ConfigurationFixtures

    @invalid_attrs %{name: nil}

    test "get_version!/1 returns the version with given id" do
      version = version_fixture()
      assert Configuration.get_version!(version.id) == version
    end

    test "create_version/1 with valid data creates a version" do
      game_mode = game_mode_fixture()
      valid_attrs = %{name: "some name", game_mode_id: game_mode.id}

      assert {:ok, %Version{} = version} = Configuration.create_version(valid_attrs)
      assert version.name == "some name"
    end

    test "create_version/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Configuration.create_version(@invalid_attrs)
    end

    test "update_version/2 with valid data updates the version" do
      version = version_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Version{} = version} = Configuration.update_version(version, update_attrs)
      assert version.name == "some updated name"
    end

    test "update_version/2 with invalid data returns error changeset" do
      version = version_fixture()
      assert {:error, %Ecto.Changeset{}} = Configuration.update_version(version, @invalid_attrs)
      assert version == Configuration.get_version!(version.id)
    end

    test "delete_version/1 deletes the version" do
      version = version_fixture()
      assert {:ok, %Version{}} = Configuration.delete_version(version)
      assert_raise Ecto.NoResultsError, fn -> Configuration.get_version!(version.id) end
    end

    test "change_version/1 returns a version changeset" do
      version = version_fixture()
      assert %Ecto.Changeset{} = Configuration.change_version(version)
    end
  end

  describe "game_modes" do
    alias GameBackend.Configuration.GameMode

    import Configurator.ConfigurationFixtures

    @invalid_attrs %{name: nil}
    test "get_game_mode!/1 returns the game_mode with given id" do
      game_mode = game_mode_fixture()
      assert Configuration.get_game_mode!(game_mode.id) == game_mode
    end

    test "create_game_mode/1 with valid data creates a game_mode" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %GameMode{} = game_mode} = Configuration.create_game_mode(valid_attrs)
      assert game_mode.name == "some name"
    end

    test "create_game_mode/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Configuration.create_game_mode(@invalid_attrs)
    end

    test "update_game_mode/2 with valid data updates the game_mode" do
      game_mode = game_mode_fixture()
      game_modes = Configuration.list_game_modes()
      update_attrs = %{name: "some updated name" <> "#{Enum.count(game_modes)}"}

      assert {:ok, %GameMode{} = game_mode} = Configuration.update_game_mode(game_mode, update_attrs)
      assert game_mode.name == "some updated name" <> "#{Enum.count(game_modes)}"
    end

    test "update_game_mode/2 with invalid data returns error changeset" do
      game_mode = game_mode_fixture()
      assert {:error, %Ecto.Changeset{}} = Configuration.update_game_mode(game_mode, @invalid_attrs)
      assert game_mode == Configuration.get_game_mode!(game_mode.id)
    end

    test "delete_game_mode/1 deletes the game_mode" do
      game_mode = game_mode_fixture()
      assert {:ok, %GameMode{}} = Configuration.delete_game_mode(game_mode)
      assert_raise Ecto.NoResultsError, fn -> Configuration.get_game_mode!(game_mode.id) end
    end

    test "change_game_mode/1 returns a game_mode changeset" do
      game_mode = game_mode_fixture()
      assert %Ecto.Changeset{} = Configuration.change_game_mode(game_mode)
    end
  end
end
