defmodule Configurator.ConfigureTest do
  use Configurator.DataCase

  alias Configurator.Configure

  describe "configurations" do
    alias Configurator.Configure.Configuration

    import Configurator.ConfigureFixtures

    @invalid_attrs %{data: "not_json", is_default: false}

    test "list_configurations/0 returns all configurations" do
      configuration = configuration_fixture()
      assert Configure.list_configurations() == [configuration]
    end

    test "get_configuration!/1 returns the configuration with given id" do
      configuration = configuration_fixture()
      assert Configure.get_configuration!(configuration.id) == configuration
    end

    test "create_configuration/1 with valid data creates a configuration" do
      valid_attrs = %{data: "{}", is_default: true}

      assert {:ok, %Configuration{} = configuration} = Configure.create_configuration(valid_attrs)
      assert configuration.data == "{}"
      assert configuration.is_default == true
    end

    test "create_configuration/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Configure.create_configuration(@invalid_attrs)
    end

    test "change_configuration/1 returns a configuration changeset" do
      configuration = configuration_fixture()
      assert %Ecto.Changeset{} = Configure.change_configuration(configuration)
    end
  end
end
