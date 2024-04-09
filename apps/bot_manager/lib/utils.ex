defmodule BotManager.Utils do
  def player_alive?(%{aditional_info: {:player, %{health: health}}}), do: health > 0

  def player_alive?(_), do: :not_a_player
end
