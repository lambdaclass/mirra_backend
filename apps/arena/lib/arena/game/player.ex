defmodule Arena.Game.Player do
  @moduledoc """
  Module for interacting with Player entity
  """
  alias Arena.Game.Skill
  alias Arena.Utils

  def add_action(player, action_name, duration_ms) do
    Process.send_after(self(), {:remove_skill_action, player.id, action_name}, duration_ms)

    update_in(player, [:aditional_info, :current_actions], fn current_actions ->
      current_actions ++ [%{action: action_name, duration: duration_ms}]
    end)
  end

  def remove_action(player, action_name) do
    update_in(player, [:aditional_info, :current_actions], fn actions ->
      Enum.reject(actions, fn action -> action.action == action_name end)
    end)
  end

  def change_health(player, health_change) do
    Map.update!(player, :aditional_info, fn info ->
      %{
        info
        | health: max(info.health - health_change, 0),
          last_damage_received: System.monotonic_time(:millisecond)
      }
    end)
  end

  def change_health(players, player_id, health_change) do
    Map.update!(players, player_id, fn player -> change_health(player, health_change) end)
  end

  def trigger_natural_healings(players) do
    Enum.reduce(players, %{}, fn {player_id, player}, players_acc ->
      player = maybe_trigger_natural_heal(player)
      Map.put(players_acc, player_id, player)
    end)
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
      max(stamina - stamina_change, 0) |> min(player.aditional_info.max_stamina)
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

  def get_skill_if_usable(player, skill_key) do
    case player.aditional_info.available_stamina > 0 do
      false -> nil
      true -> get_in(player, [:aditional_info, :skills, skill_key])
    end
  end

  def move(%{aditional_info: %{forced_movement: true}} = player, _, _) do
    player
  end

  def move(player, direction, external_wall) do
    current_actions =
      add_or_remove_moving_action(player.aditional_info.current_actions, direction)

    {x, y} = direction
    is_moving = x != 0.0 || y != 0.0

    direction =
      case is_moving do
        true -> Utils.normalize(x, y)
        _ -> player.direction
      end

    player
    |> Map.put(:direction, direction)
    |> Map.put(:is_moving, is_moving)
    |> Physics.move_entity(external_wall)
    |> Map.put(:aditional_info, Map.merge(player.aditional_info, %{current_actions: current_actions}))
  end

  def reset_forced_movement(player, reset_speed) do
    player
    |> Map.put(:is_moving, false)
    |> Map.put(:speed, reset_speed)
    |> put_in([:aditional_info, :forced_movement], false)
  end

  def forced_moving?(player) do
    player.aditional_info.forced_movement
  end

  def use_skill(player, skill_key, skill_params, game_state) do
    case get_skill_if_usable(player, skill_key) do
      false ->
        game_state

      skill ->
        action_name = skill_key_execution_action(skill_key)

        player =
          add_action(player, action_name, skill.execution_duration_ms)
          |> change_stamina(-1)

        player =
          case stamina_recharging?(player) do
            false ->
              Process.send_after(
                self(),
                {:recharge_stamina, player.id},
                player.aditional_info.stamina_interval
              )

              put_in(player, [:aditional_info, :recharging_stamina], true)

            _ ->
              player
          end

        put_in(game_state, [:players, player.id], player)
        |> Skill.do_mechanic(player, skill.mechanics, skill_params)
    end
  end

  ####################
  # Internal helpers #
  ####################
  defp skill_key_execution_action(skill_key) do
    "EXECUTING_SKILL_#{String.upcase(skill_key)}" |> String.to_existing_atom()
  end

  defp maybe_trigger_natural_heal(player) do
    now = System.monotonic_time(:millisecond)

    heal_interval? =
      player.aditional_info.last_natural_healing_update +
        player.aditional_info.natural_healing_interval < now

    damage_interval? =
      player.aditional_info.last_damage_received +
        player.aditional_info.natural_healing_damage_interval < now

    case heal_interval? and damage_interval? do
      true ->
        heal_amount = floor(player.aditional_info.base_health * 0.1)

        Map.update!(player, :aditional_info, fn info ->
          %{
            info
            | health: min(info.health + heal_amount, info.base_health),
              last_natural_healing_update: now
          }
        end)

      false ->
        player
    end
  end

  defp add_or_remove_moving_action(current_actions, direction) do
    if direction == {0.0, 0.0} do
      current_actions -- [%{action: :MOVING, duration: 0}]
    else
      current_actions ++ [%{action: :MOVING, duration: 0}]
    end
    |> Enum.uniq()
  end
end
