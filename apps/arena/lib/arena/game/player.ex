defmodule Arena.Game.Player do
  @moduledoc """
  Module for interacting with Player entity
  """

  alias Arena.Utils
  alias Arena.Game.Effect
  alias Arena.Game.Skill

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

  def take_damage(%{aditional_info: %{damage_immunity: true}} = player, _) do
    player
  end

  def take_damage(player, damage) do
    defense_multiplier = 1 - player.aditional_info.bonus_defense
    damage_taken = round(damage * defense_multiplier)

    send(self(), {:damage_taken, player.id, damage_taken})

    Map.update!(player, :aditional_info, fn info ->
      %{
        info
        | health: max(info.health - damage_taken, 0),
          last_damage_received: System.monotonic_time(:millisecond)
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

  def targetable_players(players) do
    Map.filter(players, fn {_, player} -> alive?(player) and not invisible?(player) end)
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

  def get_skill_if_usable(player, skill_key) do
    skill = get_in(player, [:aditional_info, :skills, skill_key])
    skill_cooldown = get_in(player, [:aditional_info, :cooldowns, skill_key])
    available_stamina = player.aditional_info.available_stamina

    case skill do
      %{cooldown_mechanism: "time"} when is_nil(skill_cooldown) -> skill
      %{cooldown_mechanism: "stamina", stamina_cost: cost} when cost <= available_stamina -> skill
      _ -> nil
    end
  end

  def move(%{aditional_info: %{forced_movement: true}} = player, _) do
    player
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

  def use_skill(player, skill_key, skill_params, %{
        game_state: game_state
      }) do
    case get_skill_if_usable(player, skill_key) do
      nil ->
        Process.send(self(), {:block_actions, player.id}, [])
        game_state

      skill ->
        Process.send_after(
          self(),
          {:block_actions, player.id},
          skill.execution_duration_ms
        )

        {auto_aim?, skill_direction} =
          skill_params.target
          |> Skill.maybe_auto_aim(skill, player, targetable_players(game_state.players))

        action =
          %{
            action: skill_key_execution_action(skill_key),
            duration: skill.execution_duration_ms
          }
          |> maybe_add_destination(game_state, player, skill_direction, skill)

        Process.send_after(
          self(),
          {:delayed_skill_mechanics, player.id, skill.mechanics,
           Map.merge(skill_params, %{
             skill_direction: skill_direction,
             skill_key: skill_key,
             skill_destination: action[:destination],
             auto_aim?: auto_aim?
           })
           |> Map.merge(skill)},
          skill.activation_delay_ms
        )

        Process.send_after(
          self(),
          {:delayed_effect_application, player.id, Map.get(skill, :effects_to_apply), skill.execution_duration_ms},
          skill.activation_delay_ms
        )

        player =
          add_action(player, action)
          |> apply_skill_cooldown(skill_key, skill)
          |> put_in([:direction], skill_direction |> Utils.normalize())
          |> put_in([:is_moving], false)
          |> put_in([:aditional_info, :last_skill_triggered], System.monotonic_time(:millisecond))

        put_in(game_state, [:players, player.id], player)
        |> maybe_make_player_invincible(player.id, skill)
    end
  end

  # This is a messy solution to get a mechanic result before actually running the mechanic since the client needed the
  # position in wich the player will spawn when the skill start and not when we actually execute the teleport
  # this is also optimistic since we asume the destination will be always available
  defp maybe_add_destination(action, game_state, player, skill_direction, %{mechanics: [{:teleport, teleport}]}) do
    target_position = %{
      x: player.position.x + skill_direction.x * teleport.range,
      y: player.position.y + skill_direction.y * teleport.range
    }

    final_position =
      Physics.get_closest_available_position(target_position, player, game_state.external_wall, game_state.obstacles)

    Map.put(action, :destination, final_position)
  end

  defp maybe_add_destination(action, _, _, _, _), do: action

  @doc """

  Receives a player that owns the damage and the damage number

  to calculate the real damage we'll use the config "power_up_damage_modifier" multipling that with base damage of the
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
            power_ups: power_up_amount,
            power_up_damage_modifier: power_up_damage_modifier,
            bonus_damage: bonus_damage
          }
        } = _player_damage_owner,
        damage
      ) do
    multiplier = 1 + power_up_damage_modifier * power_up_amount + bonus_damage

    (damage * multiplier)
    |> round()
  end

  def store_item(player, item) do
    put_in(player, [:aditional_info, :inventory], item)
  end

  def inventory_full?(player) do
    player.aditional_info.inventory != nil
  end

  def use_item(player, game_state, game_config) do
    case player.aditional_info.inventory do
      nil ->
        game_state

      item ->
        Enum.reduce(item.effects, game_state, fn effect_name, game_state_acc ->
          effect = Enum.find(game_config.effects, fn %{name: name} -> name == effect_name end)
          Effect.put_effect_to_entity(game_state_acc, player, player.id, effect)
        end)
        |> put_in([:players, player.id, :aditional_info, :inventory], nil)
    end
  end

  def invisible?(player) do
    get_in(player, [:aditional_info, :effects])
    |> Enum.any?(fn effect ->
      Enum.any?(effect.effect_mechanics, fn {mechanic, _} -> mechanic == :invisible end)
    end)
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
    |> Effect.apply_stat_effects()
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

        Map.update!(player, :aditional_info, fn info ->
          %{
            info
            | health: min(info.health + heal_amount, info.max_health),
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

  defp maybe_make_player_invincible(game_state, player_id, %{inmune_while_executing: true} = skill) do
    effect = %{
      name: "in_game_inmunity",
      duration_ms: skill.execution_duration_ms,
      remove_on_action: false,
      one_time_application: true,
      effect_mechanics: %{
        damage_immunity: %{
          execute_multiple_times: false,
          effect_delay_ms: 0
        }
      }
    }

    player = Map.get(game_state.players, player_id)
    Effect.put_effect_to_entity(game_state, player, player_id, effect)
  end

  defp maybe_make_player_invincible(game_state, _, _) do
    game_state
  end
end
