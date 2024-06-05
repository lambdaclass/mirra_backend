defmodule Configurator.ConfigureFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Configurator.Configure` context.
  """

  alias Configurator.GameFixtures

  @doc """
  Generate a configuration.
  """
  def configuration_fixture(attrs \\ %{}) do
    game = GameFixtures.game_fixture()
    configuration_group = configuration_group_fixture(%{game_id: game.id})

    {:ok, configuration} =
      attrs
      |> Enum.into(%{
        name: "test configuration",
        data: "{}",
        current: true,
        configuration_group_id: configuration_group.id
      })
      |> Configurator.Configure.create_configuration()

    configuration
  end

  @doc """
  Generate a configuration group.
  """
  def configuration_group_fixture(attrs \\ %{}) do
    {:ok, configuration_group} =
      attrs
      |> Enum.into(%{
        name: "Test Configuration Group"
      })
      |> Configurator.Configure.create_configuration_group()

    configuration_group
  end
end
