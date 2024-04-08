defmodule Arena.Game.Effect do
  @moduledoc """
  This module contains all the functionality related to effects
  """

  def put_effect(game_state, player_id, owner_id, effect) do
    last_id = game_state.last_id + 1
    expires_at = System.monotonic_time(:millisecond) + effect.duration_ms
    effect_extra_attributes = %{id: last_id, owner_id: owner_id, expires_at: expires_at}
    effect = Map.merge(effect, effect_extra_attributes)
    update_in(game_state, [:players, player_id, :aditional_info, :effects], fn
      # FIXME: change effects map to a list
      # nil -> [effect]
      # effects -> effects ++ [effect]
      effects -> Map.put(effects, last_id, effect)
    end)
    |> Map.put(:last_id, last_id)
  end

  ## TODO: This should be an attribute of the effect (stackable, stackable by same owner or not), not something to be decided by function callers
  ##  In addition, we should have a `caused_by` type of field so we can track the source of the effect cause
  ##  owner is not precise enough
  def put_non_owner_stackable_effect(game_state, player_id, owner_id, effect) do
    player = game_state.players[player_id]
    contain_effects? =
      Enum.any?(player.aditional_info.effects, fn {_effect_id, player_effect} ->
        player_effect.owner_id == owner_id and player_effect.name == effect.name
      end)

    if contain_effects? do
      game_state
    else
      put_effect(game_state, player_id, owner_id, effect)
    end
  end

  def remove_owner_effects(game_state, player_id, owner_id) do
    update_in(game_state, [:players, player_id, :aditional_info, :effects], fn current_effects ->
      Map.reject(current_effects, fn {_effect_id, effect} -> effect.owner_id == owner_id end)
    end)
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
