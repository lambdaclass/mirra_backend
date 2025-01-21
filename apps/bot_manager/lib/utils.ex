defmodule BotManager.Utils do
  @moduledoc """
  utils to work with nested game state operations
  """

  def player_alive?(%{aditional_info: {:player, %{health: health}}}), do: health > 0

  def player_alive?(_), do: :not_a_player

  def random_position_within_safe_zone_radius(safe_zone_radius) do
    x = Enum.random(-safe_zone_radius..safe_zone_radius) / 1.0
    y = Enum.random(-safe_zone_radius..safe_zone_radius) / 1.0

    %{x: x, y: y}
  end
end
