defmodule Arena.Game.Player do
  @moduledoc """
  Module for interacting with Player entity
  """
  def remove_action(player, action_name) do
    update_in(player, [:aditional_info, :current_actions], fn actions ->
      Enum.reject(actions, fn action -> action.name == action_name end)
    end)
  end

  def change_health(player, health_change) do
    Map.update!(player, :aditional_info, fn info ->
      %{info |
        health: max(info.health - health_change, 0),
        last_damage_received: System.monotonic_time(:millisecond)
      }
    end)
  end

  def change_health(players, player_id, health_change) do
    Map.update!(players, player_id, fn player -> change_health(player, health_change) end)
  end

  def maybe_trigger_natural_heal(player) do
    now = System.monotonic_time(:millisecond)
    heal_interval? = player.aditional_info.last_natural_healing_update + player.aditional_info.natural_healing_interval < now
    damage_interval? = player.aditional_info.last_damage_received + player.aditional_info.natural_healing_damage_interval < now
    case heal_interval? and damage_interval? do
      true ->
        heal_amount = floor(player.aditional_info.base_health * 0.1)
        Map.update!(player, :aditional_info, fn info ->
          %{info |
            health: min(info.health + heal_amount, info.base_health),
            last_natural_healing_update: now
          }
        end)
      false ->
        player
    end
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
