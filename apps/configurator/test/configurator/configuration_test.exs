defmodule Configurator.ConfigurationTest do
  use Configurator.DataCase

  alias Configurator.Configuration

  describe "characters" do
    alias Configurator.Configuration.Character

    import Configurator.ConfigurationFixtures

    @invalid_attrs %{active: nil, name: nil, base_speed: nil, base_size: nil, base_health: nil, base_stamina: nil}

    test "get_character!/1 returns the character with given id" do
      character = character_fixture()
      assert Configuration.get_character!(character.id) == character
    end

    test "create_character/1 with valid data creates a character" do
      valid_attrs = %{
        active: true,
        base_health: 42,
        base_size: "120.5",
        base_speed: "120.5",
        base_stamina: 42,
        name: "some name",
        max_inventory_size: 42,
        natural_healing_damage_interval: 42,
        natural_healing_interval: 42,
        stamina_interval: 42,
        skills: %{}
      }

      assert {:ok, %Character{} = character} = Configuration.create_character(valid_attrs)
      assert character.active == true
      assert character.name == "some name"
      assert character.base_speed == Decimal.new("120.5")
      assert character.base_size == Decimal.new("120.5")
      assert character.base_health == 42
      assert character.base_stamina == 42
    end

    test "create_character/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Configuration.create_character(@invalid_attrs)
    end

    test "update_character/2 with valid data updates the character" do
      character = character_fixture()

      update_attrs = %{
        active: false,
        name: "some updated name",
        base_speed: "456.7",
        base_size: "456.7",
        base_health: 43,
        base_stamina: 43
      }

      assert {:ok, %Character{} = character} = Configuration.update_character(character, update_attrs)
      assert character.active == false
      assert character.name == "some updated name"
      assert character.base_speed == Decimal.new("456.7")
      assert character.base_size == Decimal.new("456.7")
      assert character.base_health == 43
      assert character.base_stamina == 43
    end

    test "update_character/2 with invalid data returns error changeset" do
      character = character_fixture()
      assert {:error, %Ecto.Changeset{}} = Configuration.update_character(character, @invalid_attrs)
      assert character == Configuration.get_character!(character.id)
    end

    test "delete_character/1 deletes the character" do
      character = character_fixture()
      assert {:ok, %Character{}} = Configuration.delete_character(character)
      assert_raise Ecto.NoResultsError, fn -> Configuration.get_character!(character.id) end
    end

    test "change_character/1 returns a character changeset" do
      character = character_fixture()
      assert %Ecto.Changeset{} = Configuration.change_character(character)
    end
  end

  describe "game_configurations" do
    alias Configurator.Configuration.GameConfig

    import Configurator.ConfigurationFixtures

    @invalid_attrs %{end_game_interval_ms: nil, item_spawn_interval_ms: nil, natural_healing_interval_ms: nil, shutdown_game_wait_ms: nil, start_game_time_ms: nil, tick_rate_ms: nil, zone_damage_interval_ms: nil, zone_damage: nil, zone_shrink_interval: nil, zone_shrink_radius_by: nil, zone_shrink_start_ms: nil, zone_start_interval_ms: nil, zone_stop_interval_ms: nil}

    test "list_game_configurations/0 returns all game_configurations" do
      game_config = game_config_fixture()
      assert Configuration.list_game_configurations() == [game_config]
    end

    test "get_game_config!/1 returns the game_config with given id" do
      game_config = game_config_fixture()
      assert Configuration.get_game_config!(game_config.id) == game_config
    end

    test "create_game_config/1 with valid data creates a game_config" do
      valid_attrs = %{end_game_interval_ms: 42, item_spawn_interval_ms: 42, natural_healing_interval_ms: 42, shutdown_game_wait_ms: 42, start_game_time_ms: 42, tick_rate_ms: 42, zone_damage_interval_ms: 42, zone_damage: 42, zone_shrink_interval: 42, zone_shrink_radius_by: 42, zone_shrink_start_ms: 42, zone_start_interval_ms: 42, zone_stop_interval_ms: 42}

      assert {:ok, %GameConfig{} = game_config} = Configuration.create_game_config(valid_attrs)
      assert game_config.end_game_interval_ms == 42
      assert game_config.item_spawn_interval_ms == 42
      assert game_config.natural_healing_interval_ms == 42
      assert game_config.shutdown_game_wait_ms == 42
      assert game_config.start_game_time_ms == 42
      assert game_config.tick_rate_ms == 42
      assert game_config.zone_damage_interval_ms == 42
      assert game_config.zone_damage == 42
      assert game_config.zone_shrink_interval == 42
      assert game_config.zone_shrink_radius_by == 42
      assert game_config.zone_shrink_start_ms == 42
      assert game_config.zone_start_interval_ms == 42
      assert game_config.zone_stop_interval_ms == 42
    end

    test "create_game_config/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Configuration.create_game_config(@invalid_attrs)
    end

    test "update_game_config/2 with valid data updates the game_config" do
      game_config = game_config_fixture()
      update_attrs = %{end_game_interval_ms: 43, item_spawn_interval_ms: 43, natural_healing_interval_ms: 43, shutdown_game_wait_ms: 43, start_game_time_ms: 43, tick_rate_ms: 43, zone_damage_interval_ms: 43, zone_damage: 43, zone_shrink_interval: 43, zone_shrink_radius_by: 43, zone_shrink_start_ms: 43, zone_start_interval_ms: 43, zone_stop_interval_ms: 43}

      assert {:ok, %GameConfig{} = game_config} = Configuration.update_game_config(game_config, update_attrs)
      assert game_config.end_game_interval_ms == 43
      assert game_config.item_spawn_interval_ms == 43
      assert game_config.natural_healing_interval_ms == 43
      assert game_config.shutdown_game_wait_ms == 43
      assert game_config.start_game_time_ms == 43
      assert game_config.tick_rate_ms == 43
      assert game_config.zone_damage_interval_ms == 43
      assert game_config.zone_damage == 43
      assert game_config.zone_shrink_interval == 43
      assert game_config.zone_shrink_radius_by == 43
      assert game_config.zone_shrink_start_ms == 43
      assert game_config.zone_start_interval_ms == 43
      assert game_config.zone_stop_interval_ms == 43
    end

    test "update_game_config/2 with invalid data returns error changeset" do
      game_config = game_config_fixture()
      assert {:error, %Ecto.Changeset{}} = Configuration.update_game_config(game_config, @invalid_attrs)
      assert game_config == Configuration.get_game_config!(game_config.id)
    end

    test "delete_game_config/1 deletes the game_config" do
      game_config = game_config_fixture()
      assert {:ok, %GameConfig{}} = Configuration.delete_game_config(game_config)
      assert_raise Ecto.NoResultsError, fn -> Configuration.get_game_config!(game_config.id) end
    end

    test "change_game_config/1 returns a game_config changeset" do
      game_config = game_config_fixture()
      assert %Ecto.Changeset{} = Configuration.change_game_config(game_config)
    end
  end
end
