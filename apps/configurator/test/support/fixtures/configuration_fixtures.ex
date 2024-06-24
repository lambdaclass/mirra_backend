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
        name: "some name",
        max_inventory_size: 42,
        natural_healing_damage_interval: 42,
        natural_healing_interval: 42,
        stamina_interval: 42,
        skills: %{}
      })
      |> Configurator.Configuration.create_character()

    character
  end

  @doc """
  Generate a game_config.
  """
  def game_config_fixture(attrs \\ %{}) do
    {:ok, game_config} =
      attrs
      |> Enum.into(%{
        end_game_interval_ms: 42,
        item_spawn_interval_ms: 42,
        natural_healing_interval_ms: 42,
        shutdown_game_wait_ms: 42,
        start_game_time_ms: 42,
        tick_rate_ms: 42,
        zone_damage: 42,
        zone_damage_interval_ms: 42,
        zone_shrink_interval: 42,
        zone_shrink_radius_by: 42,
        zone_shrink_start_ms: 42,
        zone_start_interval_ms: 42,
        zone_stop_interval_ms: 42
      })
      |> Configurator.Configuration.create_game_config()

    game_config
  end
end
