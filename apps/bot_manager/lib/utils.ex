defmodule BotManager.Utils do
  @moduledoc """
  Utils to work with nested game state operations
  """

  def player_alive?(%{aditional_info: {:player, %{health: health}}}), do: health > 0

  def player_alive?(_), do: :not_a_player

  def get_random_position_within_radius(radius) do
    x = :rand.uniform() * radius
    y = :rand.uniform() * radius

    %{
      x: x,
      y: y
    }
  end
end
