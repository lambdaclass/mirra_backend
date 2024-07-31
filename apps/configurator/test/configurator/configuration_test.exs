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

  describe "versions" do
    alias GameBackend.Configuration.Version

    import Configurator.ConfigurationFixtures

    @invalid_attrs %{name: nil}

    test "get_version!/1 returns the version with given id" do
      version = version_fixture()
      assert Configuration.get_version!(version.id) == version
    end

    test "create_version/1 with valid data creates a version" do
      valid_attrs = %{name: "some name"}

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
end
