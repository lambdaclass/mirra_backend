defmodule BotManager.Utils do
  @moduledoc """
  utils to work with nested game state operations
  """

  def player_alive?(%{aditional_info: {:player, %{health: health}}}), do: health > 0

  def player_alive?(_), do: :not_a_player
end
