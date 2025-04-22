defmodule Arena.Game.Player do
  @moduledoc """
  Module for interacting with Player entity
  """

  alias Arena.GameUpdater
  alias Arena.GameTracker
  alias Arena.Utils
  alias Arena.Game.Effect
  alias Arena.Game.Skill
  alias Arena.Game.Item

  def add_action(player, action) do
    Process.send_after(self(), {:remove_skill_action, player.id, action.action}, action.duration)

    update_in(player, [:aditional_info, :current_actions], fn current_actions ->
      current_actions ++ [action]
    end)
  end

  def remove_action(player, action_name) do
    update_in(player, [:aditional_info, :current_actions], fn actions ->
      Enum.reject(actions, fn action -> action.action == action_name end)
    end)
  end

  def take_damage(%{aditional_info: %{damage_immunity: true}} = player, _, _damage_owner_id) do
    player
  end

  def take_damage(player, damage, damage_owner_id) do
    defense_multiplier = 1 - player.aditional_info.bonus_defense
    damage_taken = round(damage * defense_multiplier)

    mana_to_recover =
      if player.aditional_info.mana_recovery_strategy == "damage" do
        round(damage / player.aditional_info.max_health * player.aditional_info.mana_recovery_damage_multiplier)
      else
        0
      end

    send(self(), {:damage_taken, player.id, damage_taken})

    player =
      Map.update!(player, :aditional_info, fn info ->
        %{
          info
          | health: max(info.health - damage_taken, 0),
            last_damage_received: System.monotonic_time(:millisecond),
            mana: min(info.mana + mana_to_recover, info.max_mana)
        }
      end)

    unless alive?(player) do
      send(self(), {:to_killfeed, damage_owner_id, player.id})
    end

    player
  end

  def kill_player(player) do
    # The zone will be the one killing th character
    send(self(), {:to_killfeed, 9999, player.id})

    Map.update!(player, :aditional_info, fn info ->
      %{
        info
        | health: 0
      }
    end)
  end

  def trigger_natural_healings(players) do
    Enum.reduce(players, %{}, fn {player_id, player}, players_acc ->
      player = maybe_trigger_natural_heal(player, alive?(player))
      Map.put(players_acc, player_id, player)
    end)
  end

  def alive?(player) do
    player.aditional_info.health > 0
  end

  def alive?(players, player_id) do
    get_in(players, [player_id, :aditional_info, :health]) > 0
  end

  def alive_players(players) do
    Map.filter(players, fn {_, player} -> alive?(player) end)
  end

  def same_team?(source, target) do
    target.aditional_info.team != source.aditional_info.team
  end

  def stamina_full?(player) do
    player.aditional_info.available_stamina == player.aditional_info.max_stamina
  end

  def stamina_recharging?(player) do
    player.aditional_info.recharging_stamina
  end

  def change_stamina(player, stamina_change) do
    update_in(player, [:aditional_info, :available_stamina], fn stamina ->
      max(stamina + stamina_change, 0) |> min(player.aditional_info.max_stamina)
    end)
  end

  def recharge_stamina(player) do
    ## TODO: Review this code, there might be a better way to do the recharging
    case stamina_full?(player) do
      true ->
        Map.put(
          player,
          :aditional_info,
          Map.put(player.aditional_info, :recharging_stamina, false)
        )

      _ ->
        Process.send_after(
          self(),
          {:recharge_stamina, player.id},
          player.aditional_info.stamina_interval
        )

        change_stamina(player, 1)
    end
  end

  def set_stamina_interval(player, interval) do
    put_in(player, [:aditional_info, :stamina_interval], interval)
  end

  def revert_stamina_interval(player, revert_by, max_stamina_interval) do
    stamina_interval = min(player.aditional_info.stamina_interval + revert_by, max_stamina_interval)

    put_in(player, [:aditional_info, :stamina_interval], stamina_interval)
  end

  def add_health(player, heal_amount) do
    new_health = min(player.aditional_info.health + heal_amount, player.aditional_info.max_health)
    Map.update(player, :aditional_info, player, fn info -> %{info | health: new_health} end)
  end

  def recover_mana(player) do
    now = System.monotonic_time(:millisecond)
    time_since_last = now - player.aditional_info.mana_recovery_time_last_at

    if player.aditional_info.mana_recovery_strategy == "time" and
         time_since_last >= player.aditional_info.mana_recovery_time_interval_ms do
      change_mana(player, player.aditional_info.mana_recovery_time_amount)
      |> put_in([:aditional_info, :mana_recovery_time_last_at], now)
    else
      player
    end
  end

  def change_mana(player, mana_change) do
    update_in(player, [:aditional_info, :mana], fn mana ->
      max(mana + mana_change, 0) |> min(player.aditional_info.max_mana)
    end)
  end

  def get_skill_if_usable(player, skill_key) do
    if alive?(player) do
      skill = get_in(player, [:aditional_info, :skills, skill_key])
      skill_cooldown = get_in(player, [:aditional_info, :cooldowns, skill_key])
      available_stamina = player.aditional_info.available_stamina
      available_mana = player.aditional_info.mana

      case skill do
        %{cooldown_mechanism: "time"} when is_nil(skill_cooldown) -> skill
        %{cooldown_mechanism: "stamina", stamina_cost: cost} when cost <= available_stamina -> skill
        %{cooldown_mechanism: "mana", mana_cost: cost} when cost <= available_mana -> skill
        _ -> nil
      end
    else
      nil
    end
  end

  def move(%{aditional_info: %{forced_movement: true}} = player, _) do
    player
  end

  def move(%{aditional_info: %{health: health}} = player, _) when health <= 0 do
    player
  end

  def move(player, %{x: x, y: y}) do
    move(player, {x, y})
  end

  def move(player, direction) do
    current_actions = add_or_remove_moving_action(player.aditional_info.current_actions, direction)

    {x, y} = direction
    is_moving = x != 0.0 || y != 0.0

    direction =
      case is_moving do
        true -> Utils.normalize(%{x: x, y: y})
        _ -> player.direction
      end

    player
    |> Map.put(:direction, direction)
    |> Map.put(:is_moving, is_moving)
    |> Map.put(
      :aditional_info,
      Map.merge(player.aditional_info, %{current_actions: current_actions})
    )
  end

  def reset_forced_movement(player, reset_speed) do
    player
    |> Map.put(:is_moving, false)
    |> put_in([:aditional_info, :base_speed], reset_speed)
    |> put_in([:aditional_info, :forced_movement], false)
  end

  def change_speed(player, change_amount) do
    %{player | speed: player.speed + change_amount}
  end

  def forced_moving?(player) do
    player.aditional_info.forced_movement
  end

  def use_skill(player, skill_key, skill_params, %{game_state: game_state}) do
    case get_skill_if_usable(player, skill_key) do
      nil ->
        Process.send(self(), {:block_actions, player.id, false}, [])
        game_state

      skill ->
        {player, skill} = maybe_reset_combo(player, skill)

        GameUpdater.broadcast_player_block_movement(game_state.game_id, player.id, skill.block_movement)

        {auto_aim?, skill_direction} =
          skill_params.target
          |> Skill.maybe_auto_aim(skill, player, game_state.players)
          |> case do
            {false, _} ->
              Skill.maybe_auto_aim(skill_params.target, skill, player, game_state.crates)

            auto_aim ->
              auto_aim
          end

        execution_duration = calculate_duration(skill, player.position, skill_direction, auto_aim?)

        # For dash and leaps, we rely the unblock action message to their stop action callbacks
        is_dash_or_leap? = Enum.any?(skill.mechanics, fn mechanic -> mechanic.type in ["leap", "dash"] end)

        unless is_dash_or_leap? do
          Process.send_after(self(), {:block_actions, player.id, false}, execution_duration)
        end

        if skill.block_movement do
          send(self(), {:block_movement, player.id, true})
          Process.send_after(self(), {:block_movement, player.id, false}, execution_duration)
        end

        action =
          %{
            action: skill_key_execution_action(skill_key),
            duration: execution_duration + skill.activation_delay_ms,
            direction: skill_direction
          }
          |> maybe_add_destination(game_state, player, skill_direction, skill)

        Process.send_after(
          self(),
          {:delayed_skill_mechanics, player.id, skill.mechanics,
           Map.merge(skill_params, %{
             skill_direction: skill_direction,
             skill_key: skill_key,
             skill_destination: action[:destination],
             auto_aim?: auto_aim?,
             execution_duration: execution_duration
           })
           |> Map.merge(skill)},
          skill.activation_delay_ms
        )

        Process.send_after(self(), {:delayed_effect_application, player.id, skill}, skill.activation_delay_ms)

        player =
          add_action(player, action)
          |> apply_skill_cooldown(skill_key, skill)
          |> update_combo_sequence(skill_key, skill)
          |> maybe_face_player_towards_direction(skill_direction, skill.block_movement)
          |> put_in([:aditional_info, :last_skill_triggered], System.monotonic_time(:millisecond))
          |> update_in([:aditional_info, :last_skill_triggered_inside_bush], fn last_skill_triggered_inside_bush ->
            if player.aditional_info.on_bush do
              System.monotonic_time(:millisecond)
            else
              last_skill_triggered_inside_bush
            end
          end)

        put_in(game_state, [:players, player.id], player)
        |> maybe_make_player_invincible(player.id, skill)
    end
  end

  # This is a messy solution to get a mechanic result before actually running the mechanic since the client needed the
  # position in which the player will spawn when the skill start and not when we actually execute the teleport
  # this is also optimistic since we assume the destination will be always available
  defp maybe_add_destination(action, game_state, player, skill_direction, %{mechanics: [%{type: "teleport"} = teleport]}) do
    target_position = %{
      x: player.position.x + skill_direction.x * teleport.range,
      y: player.position.y + skill_direction.y * teleport.range
    }

    final_position =
      Physics.get_closest_available_position(target_position, player, game_state.external_wall, game_state.obstacles)

    Map.put(action, :destination, final_position)
  end

  defp maybe_add_destination(action, _, _, _, _), do: action

  defp maybe_face_player_towards_direction(player, skill_direction, true) do
    player
    |> put_in([:direction], skill_direction |> Utils.normalize())
    |> put_in([:is_moving], false)
  end

  defp maybe_face_player_towards_direction(player, _skill_direction, _), do: player

  @doc """

  Receives a player that owns the damage and the damage number

  to calculate the real damage we'll use the config "power_up_damage_modifier" multiplying that with base damage of the
  ability and multiply that with the amount of power ups that a player has then adding that to the base damage resulting
  in the real damage

  e.g.: if you want a 10% increase in damage you can add a 0.10 modifier

  ## Examples

      iex>calculate_real_damage(%{aditional_info: %{power_ups: 1, power_up_damage_modifier: 0.10, bonus_damage: 0.5}}, 40)
      64

  """
  def calculate_real_damage(
        %{
          aditional_info: %{
            base_attack: base_attack,
            power_ups: power_up_amount,
            power_up_damage_modifier: power_up_damage_modifier,
            bonus_damage: bonus_damage
          }
        } = _player_damage_owner,
        damage
      ) do
    multiplier = base_attack + power_up_damage_modifier * power_up_amount + bonus_damage

    (damage * multiplier)
    |> round()
  end

  def calculate_real_damage(
        _player_damage_owner,
        damage
      ) do
    damage
  end

  def store_item(player, item) do
    inventory = player.aditional_info.inventory

    cond do
      not Map.has_key?(inventory, 1) ->
        put_in(player, [:aditional_info, :inventory, 1], item)

      not Map.has_key?(inventory, 2) ->
        put_in(player, [:aditional_info, :inventory, 2], item)

      not Map.has_key?(inventory, 3) ->
        put_in(player, [:aditional_info, :inventory, 3], item)

      true ->
        player
    end
  end

  def inventory_full?(player) do
    Enum.count(player.aditional_info.inventory) == 3
  end

  def use_item(player, item_position, game_state) do
    case Map.get(player.aditional_info.inventory, item_position) do
      nil ->
        game_state

      item ->
        game_state =
          Effect.put_effect_to_entity(game_state, player, player.id, item.effect)
          |> maybe_update_player_item_effects_expires_at(player, item.effect)

        Item.do_mechanics(game_state, player, item.mechanics)
        |> put_in([:items, item.id, :aditional_info, :status], :ITEM_USED)
        |> put_in([:items, item.id, :aditional_info, :owner_id], player.id)
        |> put_in(
          [:players, player.id, :aditional_info, :inventory],
          Map.delete(player.aditional_info.inventory, item_position)
        )
    end
  end

  def visible?(source_player, target_player) do
    target_player.id in source_player.aditional_info.visible_players
  end

  def remove_expired_effects(player) do
    now = System.monotonic_time(:millisecond)

    effects =
      player.aditional_info.effects
      |> Enum.filter(fn effect -> is_nil(effect.expires_at) or effect.expires_at > now end)

    put_in(player, [:aditional_info, :effects], effects)
  end

  def remove_effects_on_action(player) do
    now = System.monotonic_time(:millisecond)

    effects =
      player.aditional_info.effects
      |> Enum.reject(fn effect ->
        effect.remove_on_action and
          effect.action_removal_at <= now and
          Enum.any?(player.aditional_info.current_actions, fn action -> action.action != :MOVING end)
      end)

    put_in(player, [:aditional_info, :effects], effects)
  end

  def reset_effects(player) do
    player
    |> put_in([:speed], player.aditional_info.base_speed)
    |> put_in([:radius], player.aditional_info.base_radius)
    |> put_in([:aditional_info, :stamina_interval], player.aditional_info.base_stamina_interval)
    |> put_in([:aditional_info, :cooldown_multiplier], player.aditional_info.base_cooldown_multiplier)
    |> put_in([:aditional_info, :bonus_damage], 0)
    |> put_in([:aditional_info, :bonus_defense], 0)
    |> put_in([:aditional_info, :damage_immunity], false)
    |> put_in([:aditional_info, :pull_immunity], false)
    |> Effect.apply_stat_effects()
  end

  def player_executing_skill?(player) do
    Enum.any?(player.aditional_info.current_actions, fn current_action ->
      Atom.to_string(current_action.action)
      |> case do
        "EXECUTING_SKILL" <> _number -> true
        _ -> false
      end
    end)
  end

  def power_up_boost(player, amount_of_power_ups, game_config) do
    player
    |> update_in([:aditional_info, :power_ups], fn amount -> amount + amount_of_power_ups end)
    |> update_in([:aditional_info], fn additional_info ->
      Enum.reduce(1..amount_of_power_ups, additional_info, fn _times, additional_info ->
        additional_info
        |> Map.update(:health, additional_info.health, fn current_health ->
          Utils.increase_value_by_base_percentage(
            current_health,
            additional_info.base_health,
            game_config.game.power_up_health_modifier
          )
        end)
        |> Map.update(:max_health, additional_info.max_health, fn max_health ->
          Utils.increase_value_by_base_percentage(
            max_health,
            additional_info.base_health,
            game_config.game.power_up_health_modifier
          )
        end)
      end)
    end)
  end

  def respawn_player(player, position) do
    aditional_info =
      player.aditional_info
      |> Map.put(:max_health, player.aditional_info.base_health)
      |> Map.put(:health, player.aditional_info.base_health)
      |> Map.put(:effects, [])
      |> Map.put(:power_ups, 0)

    player
    |> Map.put(:aditional_info, aditional_info)
    |> Map.put(:position, position)
  end

  ####################
  # Internal helpers #
  ####################
  defp skill_key_execution_action("1"), do: :EXECUTING_SKILL_1
  defp skill_key_execution_action("2"), do: :EXECUTING_SKILL_2
  defp skill_key_execution_action("3"), do: :EXECUTING_SKILL_3

  defp maybe_trigger_natural_heal(player, true) do
    now = System.monotonic_time(:millisecond)

    heal_interval? =
      player.aditional_info.last_natural_healing_update +
        player.aditional_info.natural_healing_interval < now

    damage_interval? =
      player.aditional_info.last_damage_received +
        player.aditional_info.natural_healing_damage_interval < now

    use_skill_interval? =
      player.aditional_info.last_skill_triggered +
        player.aditional_info.natural_healing_damage_interval < now

    case heal_interval? and damage_interval? and use_skill_interval? do
      true ->
        heal_amount = floor(player.aditional_info.max_health * 0.1)
        new_health = min(player.aditional_info.health + heal_amount, player.aditional_info.max_health)

        GameTracker.push_event(self(), {:heal, player.id, new_health - player.aditional_info.health})

        Map.update!(player, :aditional_info, fn info ->
          %{
            info
            | health: new_health,
              last_natural_healing_update: now
          }
        end)

      false ->
        player
    end
  end

  defp maybe_trigger_natural_heal(player, _), do: player

  defp add_or_remove_moving_action(current_actions, direction) do
    if direction == {0.0, 0.0} do
      current_actions -- [%{action: :MOVING, duration: 0}]
    else
      current_actions ++ [%{action: :MOVING, duration: 0}]
    end
    |> Enum.uniq()
  end

  defp apply_skill_cooldown(player, skill_key, %{cooldown_mechanism: "time", cooldown_ms: cooldown_ms}) do
    put_in(
      player,
      [:aditional_info, :cooldowns, skill_key],
      round(cooldown_ms * player.aditional_info.cooldown_multiplier)
    )
  end

  defp apply_skill_cooldown(player, _skill_key, %{cooldown_mechanism: "stamina", stamina_cost: cost}) do
    player = change_stamina(player, -cost)

    case stamina_recharging?(player) do
      false ->
        Process.send_after(self(), {:recharge_stamina, player.id}, player.aditional_info.stamina_interval)
        put_in(player, [:aditional_info, :recharging_stamina], true)

      _ ->
        player
    end
  end

  defp apply_skill_cooldown(player, _skill_key, %{cooldown_mechanism: "mana", mana_cost: cost}) do
    change_mana(player, -cost)
  end

  defp maybe_reset_combo(player, %{is_combo?: false} = skill), do: {player, skill}

  defp maybe_reset_combo(player, skill) do
    now = System.monotonic_time(:millisecond)
    combo_time_ms = now - Map.get(player.aditional_info, :last_combo_timestamp, now)
    player = put_in(player, [:aditional_info, :last_combo_timestamp], now)

    if combo_time_ms > skill.reset_combo_ms do
      player = put_in(player, [:aditional_info, :current_basic_animation], 1)

      {player, Map.get(skill, :first_skill, skill)}
    else
      player = put_in(player, [:aditional_info, :current_basic_animation], get_skill_animation(skill.name))

      {player, skill}
    end
  end

  defp update_combo_sequence(player, _skill_key, %{is_combo?: false}), do: player

  defp update_combo_sequence(player, skill_key, skill) do
    first_skill = Map.get(skill, :first_skill, skill)

    if is_nil(skill.next_skill) do
      put_in(player, [:aditional_info, :skills, skill_key], first_skill)
    else
      next_skill = skill.next_skill |> Map.put(:first_skill, first_skill)

      put_in(player, [:aditional_info, :skills, skill_key], next_skill)
    end
  end

  ## Yes, we are pattern matching on exactly one mechanic. As of time writing we only have one mechanic per skill
  ## so to simplify my life an executive decision was made to take thas as a fact
  ## When the time comes to have more than one mechanic per skill this function will need to be refactored, good thing
  ## is that it will crash here so not something we can ignore
  defp calculate_duration(%{mechanics: [%{type: "leap"} = leap]}, position, direction, auto_aim?) do
    ## TODO: Cap target_position to leap.range
    direction = Skill.maybe_multiply_by_range(direction, auto_aim?, leap.range)

    target_position = %{
      x: position.x + direction.x,
      y: position.y + direction.y
    }

    Physics.calculate_duration(position, target_position, leap.speed, leap.range)
  end

  defp calculate_duration(%{mechanics: [_]} = skill, _, _, _) do
    skill.execution_duration_ms
  end

  defp maybe_make_player_invincible(game_state, player_id, %{inmune_while_executing: true} = skill) do
    effect = %{
      name: "in_game_inmunity",
      duration_ms: skill.execution_duration_ms,
      remove_on_action: false,
      one_time_application: true,
      effect_mechanics: [
        %{
          name: "damage_immunity",
          effect_delay_ms: 0,
          execute_multiple_times: false
        },
        %{
          name: "pull_immunity",
          effect_delay_ms: 0,
          execute_multiple_times: false
        }
      ]
    }

    player = Map.get(game_state.players, player_id)
    Effect.put_effect_to_entity(game_state, player, player_id, effect)
  end

  defp maybe_make_player_invincible(game_state, _, _) do
    game_state
  end

  defp get_skill_animation("kenzu_quickslash_second"), do: 2
  defp get_skill_animation("kenzu_quickslash_third"), do: 3

  defp get_skill_animation(_skill_name), do: 1

  defp maybe_update_player_item_effects_expires_at(game_state, player, %{duration_ms: duration_ms} = _effect)
       when not is_nil(duration_ms) do
    duration =
      System.monotonic_time(:millisecond) + duration_ms

    game_state
    |> update_in([:players, player.id, :aditional_info, :item_effects_expires_at], fn item_duration ->
      max(item_duration, duration)
    end)
  end

  defp maybe_update_player_item_effects_expires_at(game_state, _player, _effect) do
    game_state
  end
end
