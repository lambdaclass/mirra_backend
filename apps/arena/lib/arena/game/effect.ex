defmodule Arena.Game.Effect do
  @moduledoc """
  This module contains all the functionality related to effects
  """

  alias Arena.GameUpdater
  alias Arena.Game.Player
  alias Arena.Entities

  @doc """
  Add an effect to any kind of entity
  if the entity already has that effect from with the same owner_id and the effect
  param has the flag one_time_application in true it won't be re applied

  ## Examples

    iex> put_effect_to_entity(game_state, entity, owner_id, effect)
    %{aditional_info: effects: [effect]}

  """

  def put_effect_to_entity(game_state, entity, owner_id, effect) do
    put_effect_to_entity(game_state, entity, owner_id, 0, effect)
  end

  def put_effect_to_entity(game_state, entity, owner_id, start_action_removal_in_ms, effect) do
    last_id = game_state.last_id + 1

    entity_contain_effect? =
      Enum.any?(entity.aditional_info.effects, fn entity_effect ->
        entity_effect.owner_id == owner_id and entity_effect.name == effect.name
      end)

    updated_entity =
      if entity_contain_effect? and effect.one_time_application do
        entity
      else
        now = System.monotonic_time(:millisecond)
        action_removal_at = now + start_action_removal_in_ms

        expires_at =
          case effect[:duration_ms] do
            nil -> nil
            duration_ms -> now + duration_ms
          end

        ## TODO: remove `id` from effect, unless it is really necessary
        effect_extra_attributes = %{
          id: last_id,
          owner_id: owner_id,
          expires_at: expires_at,
          action_removal_at: action_removal_at
        }

        update_in(
          entity,
          [:aditional_info, :effects],
          fn effects -> effects ++ [Map.merge(effect, effect_extra_attributes)] end
        )
      end

    GameUpdater.update_entity_in_game_state(game_state, updated_entity)
    |> Map.put(:last_id, last_id)
  end

  def remove_owner_effects(game_state, entity_id, owner_id) do
    cond do
      Map.has_key?(game_state.players, entity_id) ->
        update_in(game_state, [:players, entity_id, :aditional_info, :effects], fn current_effects ->
          Enum.reject(current_effects, fn effect -> effect.owner_id == owner_id end)
        end)

      Map.has_key?(game_state.players, entity_id) ->
        update_in(game_state, [:crates, entity_id, :aditional_info, :effects], fn current_effects ->
          Enum.reject(current_effects, fn effect -> effect.owner_id == owner_id end)
        end)

      true ->
        game_state
    end
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

  defp apply_stat_modifier(player, {:damage_change, damage_change}) do
    update_in(player, [:aditional_info, :bonus_damage], fn bonus_damage -> bonus_damage + damage_change.modifier end)
  end

  defp apply_stat_modifier(player, {:defense_change, defense_change}) do
    update_in(player, [:aditional_info, :bonus_defense], fn bonus_defense -> bonus_defense + defense_change.modifier end)
  end

  defp apply_stat_modifier(player, {:reduce_stamina_interval, reduce_stamina_interval}) do
    stamina_speedup_by =
      (player.aditional_info.stamina_interval * reduce_stamina_interval.decrease_by)
      |> round()

    new_stamina_interval = player.aditional_info.stamina_interval - stamina_speedup_by

    put_in(player, [:aditional_info, :stamina_interval], new_stamina_interval)
  end

  defp apply_stat_modifier(player, {:reduce_cooldowns_duration, reduce_cooldowns_duration}) do
    put_in(player, [:aditional_info, :cooldown_multiplier], reduce_cooldowns_duration.multiplier)
  end

  defp apply_stat_modifier(player, {:speed_boost, speed_boost}) do
    %{player | speed: player.speed * (1 + speed_boost.modifier)}
  end

  defp apply_stat_modifier(player, {:modify_radius, modify_radius}) do
    %{player | radius: player.radius * (1 + modify_radius.modifier)}
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

  def apply_effect_mechanic(%{players: players, pools: pools, crates: crates} = game_state) do
    game_state =
      Enum.reduce(crates, game_state, fn {crate_id, crate}, game_state ->
        if crate.aditional_info.status == :FINE do
          crate =
            Enum.reduce(crate.aditional_info.effects, crate, fn effect, crate ->
              apply_effect_mechanic(crate, effect, game_state)
            end)

          put_in(game_state, [:crates, crate_id], crate)
        else
          game_state
        end
      end)

    game_state =
      Enum.reduce(players, game_state, fn {_player_id, player}, game_state ->
        if Player.alive?(player) do
          player =
            Enum.reduce(player.aditional_info.effects, player, fn effect, player ->
              apply_effect_mechanic(player, effect, game_state)
            end)

          put_in(game_state, [:players, player.id], player)
        else
          game_state
        end
      end)

    Enum.reduce(pools, game_state, fn {_pool_id, pool}, game_state ->
      pool =
        Enum.reduce(pool.aditional_info.effects, pool, fn effect, pool ->
          apply_effect_mechanic(pool, effect, game_state)
        end)

      put_in(game_state, [:pools, pool.id], pool)
    end)
  end

  defp apply_effect_mechanic(entity, effect, game_state) do
    now = System.monotonic_time(:millisecond)

    Enum.reduce(effect.effect_mechanics, entity, fn {mechanic_name, mechanic_params} = mechanic, entity ->
      execute_multiple_times? =
        mechanic_params.execute_multiple_times or is_nil(Map.get(mechanic_params, :last_application_time))

      enough_time_passed? =
        is_nil(Map.get(mechanic_params, :last_application_time)) or
          now - Map.get(mechanic_params, :last_application_time) >= mechanic_params.effect_delay_ms

      if execute_multiple_times? and enough_time_passed? do
        do_effect_mechanics(game_state, entity, effect, mechanic)
        |> put_in_effect(effect, [:effect_mechanics, mechanic_name, :last_application_time], now)
      else
        entity
      end
    end)
  end

  defp do_effect_mechanics(game_state, entity, effect, {:pull, pull_params}) do
    case Map.get(game_state.pools, effect.owner_id) do
      nil ->
        entity

      %{position: pool_position} when pool_position == entity.position ->
        entity

      pool ->
        if entity.aditional_info.damage_immunity do
          entity
        else
          direction = Physics.get_direction_from_positions(entity.position, pool.position)

          pull_force =
            pull_params.force + pull_params.force * pool.aditional_info.stat_multiplier

          Physics.move_entity_to_direction(
            entity,
            direction,
            pull_force,
            game_state.external_wall,
            game_state.obstacles
          )
          |> Map.put(:aditional_info, entity.aditional_info)
          |> Map.put(:collides_with, entity.collides_with)
        end
    end
  end

  defp do_effect_mechanics(game_state, entity, effect, {:damage, damage_params}) do
    # TODO not all effects may come from pools entities, maybe we should update this when we implement other skills that
    # applies this effect
    Map.get(game_state.pools, effect.owner_id)
    |> case do
      nil ->
        entity

      pool ->
        pool_owner = Map.get(game_state.players, pool.aditional_info.owner_id)
        real_damage = Player.calculate_real_damage(pool_owner, damage_params.damage)

        send(self(), {:damage_done, pool_owner.id, real_damage})

        Entities.take_damage(entity, real_damage)
        |> maybe_send_to_killfeed(pool_owner.id)
    end
  end

  defp do_effect_mechanics(game_state, player, _effect, {:buff_pool, buff_attributes}) do
    Map.get(game_state.pools, player.id)
    |> case do
      nil ->
        player

      pool ->
        update_in(pool, [:aditional_info, :stat_multiplier], fn
          current_multiplier when current_multiplier > 0 ->
            current_multiplier + current_multiplier * buff_attributes.stat_multiplier

          _current_multiplier ->
            buff_attributes.stat_multiplier
        end)
        |> update_in([:aditional_info, :duration_ms], fn current_duration ->
          current_duration + buff_attributes.additive_duration_add_ms
        end)
    end
  end

  defp do_effect_mechanics(_game_state, player, _effect, {:refresh_stamina, _refresh_stamina}) do
    put_in(player, [:aditional_info, :available_stamina], player.aditional_info.max_stamina)
  end

  defp do_effect_mechanics(_game_state, player, _effect, {:refresh_cooldowns, _refresh_cooldowns}) do
    put_in(player, [:aditional_info, :cooldowns], %{})
  end

  ## Sink for mechanics that don't do anything
  defp do_effect_mechanics(_game_state, player, _effect, _mechanic) do
    player
  end

  defp maybe_send_to_killfeed(%{category: :player} = entity, pool_owner_id) do
    unless Player.alive?(entity) do
      send(self(), {:to_killfeed, pool_owner_id, entity.id})
    end

    entity
  end

  defp maybe_send_to_killfeed(entity, _pool_owner_id), do: entity
end
