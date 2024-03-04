defmodule Configurator.ConfigureFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Configurator.Configure` context.
  """

  @doc """
  Generate a configuration.
  """
  def configuration_fixture(attrs \\ %{}) do
    {:ok, configuration} =
      attrs
      |> Enum.into(%{
        data: %{},
        is_default: true
      })
      |> Configurator.Configure.create_configuration()

    configuration
  end
end
