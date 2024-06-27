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
end
