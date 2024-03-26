defmodule Arena.Game.Effect do
  @moduledoc """
  This module contains all the functionality related to effects
  """

  @doc """
  This function applies the mechanics considered "stat modifiers", this means the effect mechanics
  modify the player stats/attributes

  **Important**: This function assumes the effects are already in the player's effects list
  """
  def apply_stat_effects(player) do
    Enum.reduce(player.effects, player, fn {_effect_id, effect}, player_acc ->
      apply_stat_effect(player_acc, effect)
    end)
  end

  defp apply_stat_effect(player, effect) do
    Enum.reduce(effect.mechanics, player, fn mechanic, player_acc ->
      apply_stat_modifier(player_acc, mechanic)
    end)
  end

  defp apply_stat_modifier(player, {:damage_up, damage_up}) do
    update_in(player, [:aditional_info, :bonus_damage], fn bonus_damage -> bonus_damage + damage_up end)
  end

  defp apply_stat_modifier(player, _) do
    player
  end
end
