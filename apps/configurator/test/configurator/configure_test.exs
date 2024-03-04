defmodule Configurator.ConfigureTest do
  use Configurator.DataCase

  alias Configurator.Configure

  describe "configurations" do
    alias Configurator.Configure.Configuration

    import Configurator.ConfigureFixtures

    @invalid_attrs %{data: nil, is_default: nil}

    test "list_configurations/0 returns all configurations" do
      configuration = configuration_fixture()
      assert Configure.list_configurations() == [configuration]
    end

    test "get_configuration!/1 returns the configuration with given id" do
      configuration = configuration_fixture()
      assert Configure.get_configuration!(configuration.id) == configuration
    end

    test "create_configuration/1 with valid data creates a configuration" do
      valid_attrs = %{data: %{}, is_default: true}

      assert {:ok, %Configuration{} = configuration} = Configure.create_configuration(valid_attrs)
      assert configuration.data == %{}
      assert configuration.is_default == true
    end

    test "create_configuration/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Configure.create_configuration(@invalid_attrs)
    end

    test "update_configuration/2 with valid data updates the configuration" do
      configuration = configuration_fixture()
      update_attrs = %{data: %{}, is_default: false}

      assert {:ok, %Configuration{} = configuration} = Configure.update_configuration(configuration, update_attrs)
      assert configuration.data == %{}
      assert configuration.is_default == false
    end

    test "update_configuration/2 with invalid data returns error changeset" do
      configuration = configuration_fixture()
      assert {:error, %Ecto.Changeset{}} = Configure.update_configuration(configuration, @invalid_attrs)
      assert configuration == Configure.get_configuration!(configuration.id)
    end

    test "delete_configuration/1 deletes the configuration" do
      configuration = configuration_fixture()
      assert {:ok, %Configuration{}} = Configure.delete_configuration(configuration)
      assert_raise Ecto.NoResultsError, fn -> Configure.get_configuration!(configuration.id) end
    end

    test "change_configuration/1 returns a configuration changeset" do
      configuration = configuration_fixture()
      assert %Ecto.Changeset{} = Configure.change_configuration(configuration)
    end
  end
end
