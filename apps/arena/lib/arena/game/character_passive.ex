defmodule Arena.Game.CharacterPassive do

  def activate_on_hit_passive(%{aditional_info: %{passive: %{name: "heatshield"}}} = player, damage_taken) do
    %{
      aditional_info: %{
        passive: %{parameters: parameters},
        max_health: max_health,
        health: current_health
      }
    } = player
    damage_reduction_percentage = round(((max_health - current_health) / max_health) * parameters.max_damage_reduction) / 100
    damage_reduction_multiplier = 1 - damage_reduction_percentage
    round(damage_taken * damage_reduction_multiplier)
  end

  def has_on_hit_passive?(%{aditional_info: %{passive: %{type: "on_hit_received"}}} = _player), do: true
  def has_on_hit_passive?(_player), do: false
end
