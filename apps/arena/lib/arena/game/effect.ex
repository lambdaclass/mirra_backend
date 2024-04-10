defmodule Arena.Game.Effect do
  @moduledoc """
  This module contains all the functionality related to effects
  """

  def put_effect(game_state, player_id, owner_id, effect) do
    last_id = game_state.last_id + 1

    expires_at =
      case effect[:duration_ms] do
        nil -> nil
        duration_ms -> System.monotonic_time(:millisecond) + duration_ms
      end

    ## TODO: remove `id` from effect, unless it is really necessary
    effect_extra_attributes = %{id: last_id, owner_id: owner_id, expires_at: expires_at}
    effect = Map.merge(effect, effect_extra_attributes)

    update_in(game_state, [:players, player_id, :aditional_info, :effects], fn
      nil -> [effect]
      effects -> effects ++ [effect]
    end)
    |> Map.put(:last_id, last_id)
  end

  ## TODO: This should be an attribute of the effect (stackable, stackable by same owner or not), not something to be decided by function callers
  ##  In addition, we should have a `caused_by` type of field so we can track the source of the effect cause
  ##  owner is not precise enough
  def put_non_owner_stackable_effect(game_state, player_id, owner_id, effect) do
    player = game_state.players[player_id]

    contain_effects? =
      Enum.any?(player.aditional_info.effects, fn player_effect ->
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
      Enum.reject(current_effects, fn effect -> effect.owner_id == owner_id end)
    end)
  end

  @doc """
  This function applies the mechanics considered "stat modifiers", this means the effect mechanics
  modify the player stats/attributes

  **Important**: This function should only be called by the tick function and it
      assumes the effects are already in the player's effects list
  """
  def apply_stat_effects(player) do
    Enum.reduce(player.aditional_info.effects, player, fn effect, player_acc ->
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

  @doc """
  This function finds an updates the given attributes of an effect in a player list of effects
  """
  def put_in_effect(player, effect, keys, value) do
    update_in(player, [:aditional_info, :effects], fn effects ->
      Enum.map(effects, fn current_effect ->
        if current_effect.id == effect.id do
          put_in(current_effect, keys, value)
        else
          current_effect
        end
      end)
    end)
  end
end
