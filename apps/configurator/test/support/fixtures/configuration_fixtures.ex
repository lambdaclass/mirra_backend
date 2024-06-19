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
        name: "some name"
      })
      |> Configurator.Configuration.create_character()

    character
  end
end
