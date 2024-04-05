defmodule Arena.Game.Effect do
  @moduledoc """
  This module contains all the functionality related to effects
  """

  def put_effect(game_state, player_id, owner_id, effect) do
    last_id = game_state.last_id + 1
    ## TODO: add end_at timestamp so we can remove it later on
    effect = Map.merge(effect, %{id: last_id, owner_id: owner_id})
    update_in(game_state, [:players, player_id, :aditional_info, :effects], fn
      # FIXME: change effects map to a list
      # nil -> [effect]
      # effects -> effects ++ [effect]
      effects -> Map.put(effects, last_id, effect)
    end)
    |> Map.put(:last_id, last_id)
  end

  @doc """
  This function applies the mechanics considered "stat modifiers", this means the effect mechanics
  modify the player stats/attributes

  **Important**: This function should only be called by the tick function and it
      assumes the effects are already in the player's effects list
  """
  def apply_stat_effects(player) do
    Enum.reduce(player.aditional_info.effects, player, fn {_effect_id, effect}, player_acc ->
      apply_stat_effect(player_acc, effect)
    end)
  end

  defp apply_stat_effect(player, effect) do
    Enum.reduce(effect.effect_mechanics, player, fn mechanic, player_acc ->
      apply_stat_modifier(player_acc, mechanic)
    end)
  end

  defp apply_stat_modifier(player, {:damage_up, damage_up}) do
    update_in(player, [:aditional_info, :bonus_damage], fn bonus_damage -> bonus_damage + damage_up end)
  end

  defp apply_stat_modifier(player, {:reduce_stamina_interval, reduce_stamina_interval}) do
    stamina_speedup_by =
      (player.aditional_info.stamina_interval * reduce_stamina_interval.decrease_by)
      |> round()

    new_stamina_interval = player.aditional_info.stamina_interval - stamina_speedup_by

    put_in(player, [:aditional_info, :stamina_interval], new_stamina_interval)
  end

  defp apply_stat_modifier(player, {:speed_boost, speed_boost}) do
    %{player | speed: player.speed + speed_boost.amount}
  end

  defp apply_stat_modifier(player, {:damage_immunity, _damage_immunity}) do
    put_in(player, [:aditional_info, :damage_immunity], true)
  end

  defp apply_stat_modifier(player, _) do
    player
  end
end
