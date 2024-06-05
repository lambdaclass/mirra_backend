defmodule Configurator.ConfigureTest do
  use Configurator.DataCase

  alias Configurator.Configure
  import Configurator.ConfigureFixtures
  import Configurator.GameFixtures

  describe "configurations" do
    setup [:setup_game, :setup_configuration_group]
    alias Configurator.Configure.Configuration

    @invalid_attrs %{data: "not_json", current: false}

    test "list_configurations/0 returns all configurations" do
      configuration = configuration_fixture()
      assert Configure.list_configurations() == [configuration]
    end

    test "get_configuration!/1 returns the configuration with given id" do
      configuration = configuration_fixture()
      assert Configure.get_configuration!(configuration.id) == configuration
    end

    test "create_configuration/1 with valid data creates a configuration" do
      game = game_fixture()
      configuration_group = configuration_group_fixture(game_id: game.id)
      valid_attrs = %{name: "name", data: "{}", current: true, configuration_group_id: configuration_group.id}

      assert {:ok, %Configuration{} = configuration} = Configure.create_configuration(valid_attrs)
      assert configuration.data == "{}"
      assert configuration.current == true
    end

    test "create_configuration/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Configure.create_configuration(@invalid_attrs)
    end

    test "change_configuration/1 returns a configuration changeset" do
      configuration = configuration_fixture()
      assert %Ecto.Changeset{} = Configure.change_configuration(configuration)
    end
  end

  def setup_game(_) do
    game = game_fixture()
    %{game: game}
  end

  def setup_configuration_group(%{game: game}) do
    configuration_group = configuration_group_fixture(game_id: game.id)
    %{configuration_group: configuration_group}
  end
end
