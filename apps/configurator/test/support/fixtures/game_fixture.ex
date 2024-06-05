defmodule Configurator.GameFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Configurator.Games` context.
  """

  @doc """
  Generate a game
  """
  def game_fixture(attrs \\ %{}) do
    {:ok, game} =
      attrs
      |> Enum.into(%{name: "Test Game"})
      |> Configurator.Games.create_game()

    game
  end
end
