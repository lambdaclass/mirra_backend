defmodule Arena.Game.Player do
  def change_health(player, health_change) do
    update_in(player, [:aditional_info, :health], fn health -> max(health - health_change, 0) end)
  end

  def change_health(players, player_id, health_change) do
    Map.update!(players, player_id, fn player -> change_health(player, health_change) end)
  end

  def is_alive?(player) do
    player.aditional_info.health > 0
  end

  def is_alive?(players, player_id) do
    get_in(players, [player_id, :aditional_info, :health]) > 0
  end

  def stamina_full?(player) do
    player.aditional_info.available_stamina == player.aditional_info.max_stamina
  end

  # def stamina_available?(player) do
  #   player.aditional_info.available_stamina > 0
  # end

  def change_stamina(player, stamina_change) do
    update_in(player, [:aditional_info, :available_stamina], fn stamina -> max(stamina - stamina_change, 0) end)
  end
end
