defmodule Configurator.ConfigurationFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Configurator.Configuration` context.
  """

  @doc """
  Generate a character.
  """
  def character_fixture(attrs \\ %{}) do
    {:ok, character} =
      attrs
      |> Enum.into(%{
        active: true,
        base_health: 42,
        base_size: "120.5",
        base_speed: "120.5",
        base_stamina: 42,
        name: "some name" <> (Enum.random(1..99_999_999) |> to_string()),
        max_inventory_size: 42,
        natural_healing_damage_interval: 42,
        natural_healing_interval: 42,
        stamina_interval: 42,
        skills: %{},
        game_id: 1,
        faction: "ogre"
      })
      |> GameBackend.Units.Characters.insert_character()

    character
  end
end
