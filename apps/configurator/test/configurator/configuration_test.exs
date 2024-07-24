defmodule Configurator.ConfigurationTest do
  use Configurator.DataCase

  alias GameBackend.Configuration

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
