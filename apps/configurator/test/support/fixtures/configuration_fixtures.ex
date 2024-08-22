defmodule Configurator.ConfigurationFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Configurator.Configuration` context.
  """

  @doc """
  Generate a character.
  """
  def character_fixture(attrs \\ %{}) do
    version = version_fixture()

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
        faction: "ogre",
        version_id: version.id
      })
      |> GameBackend.Units.Characters.insert_character()

    character
  end

  @doc """
  Generate a map_configuration.
  """
  def map_configuration_fixture(attrs \\ %{}) do
    version = version_fixture()

    {:ok, map_configuration} =
      attrs
      |> Enum.into(%{
        bushes: [],
        initial_positions: [],
        obstacles: [],
        radius: "120.5",
        version_id: version.id,
        active: true
      })
      |> GameBackend.Configuration.create_map_configuration()

    map_configuration
  end

  @doc """
  Generate a arena_server.
  """
  def arena_server_fixture(attrs \\ %{}) do
    {:ok, arena_server} =
      attrs
      |> Enum.into(%{
        ip: "some ip",
        name: "some name",
        url: "some url",
        status: :active,
        environment: :production
      })
      |> GameBackend.Configuration.create_arena_server()

    arena_server
  end

  @doc """
  Generate a version.
  """
  def version_fixture(attrs \\ %{}) do
    {:ok, version} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> GameBackend.Configuration.create_version()

    version
  end
end
