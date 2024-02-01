defmodule Arena.Game.Player do
  @moduledoc """
  Module for interacting with Player entity
  """
  def change_health(player, health_change) do
    update_in(player, [:aditional_info, :health], fn health -> max(health - health_change, 0) end)
  end

  def change_health(players, player_id, health_change) do
    Map.update!(players, player_id, fn player -> change_health(player, health_change) end)
  end

  def alive?(player) do
    player.aditional_info.health > 0
  end

  def alive?(players, player_id) do
    get_in(players, [player_id, :aditional_info, :health]) > 0
  end

  def stamina_full?(player) do
    player.aditional_info.available_stamina == player.aditional_info.max_stamina
  end

  def stamina_recharging?(player) do
    player.aditional_info.recharging_stamina
  end

  def change_stamina(player, stamina_change) do
    update_in(player, [:aditional_info, :available_stamina], fn stamina ->
      max(stamina - stamina_change, 0)
    end)
  end

  def get_skill_if_usable(player, skill_key) do
    case player.aditional_info.available_stamina > 0 do
      false -> nil
      true -> get_in(player, [:aditional_info, :skills, skill_key])
    end
  end
end
