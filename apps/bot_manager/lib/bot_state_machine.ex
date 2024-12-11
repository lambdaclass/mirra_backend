defmodule BotManager.BotStateMachine do
  @moduledoc """
  This module will take care of deciding what the bot will do on each deciding step
  """

  alias BotManager.Utils
  alias BotManager.Math.Vector

  @skill_1_key "1"
  @skill_2_key "2"
  @dash_skill_key "3"

  def decide_action(%{bots_enabled?: false}) do
    {:move, %{x: 0, y: 0}}
  end

  def decide_action(%{game_state: game_state, bot_player: bot_player, attack_blocked: attack_blocked, config: config}) do
    players_with_distances = map_directions_to_players(game_state, bot_player)

    closest_player =
      players_with_distances
      |> Enum.min_by(fn player_info -> player_info.distance end)

    random_distance = 1000

    cond do
      attack_blocked ->
        :stand

      closest_player.distance > random_distance ->
        determine_player_move_action(bot_player, closest_player.direction)

      closest_player.distance < 50 ->
        {:move, create_random_direction()}

      closest_player.distance <= random_distance ->
        detemine_player_attack(bot_player, closest_player, config)
        {:attack, closest_player.direction}

      true ->
        {:move, create_random_direction()}
    end
  end

  def decide_action(_), do: :stand

  defp create_random_direction() do
    %{x: Enum.random(1..200) / 100 - 1, y: Enum.random(1..200) / 100 - 1}
  end

  defp map_directions_to_players(game_state, bot_player) do
    Map.delete(game_state.players, bot_player.id)
    |> Map.filter(fn {player_id, player} ->
      Utils.player_alive?(player) && player_within_visible_players?(bot_player, player_id)
    end)
    |> Enum.map(fn {_player_id, player} ->
      player_info =
        get_distance_and_direction_to_positions(bot_player.position, player.position)

      Map.merge(player, player_info)
    end)
  end

  defp get_distance_and_direction_to_positions(base_position, end_position) do
    %{x: x, y: y} = Vector.sub(end_position, base_position)
    distance = :math.sqrt(:math.pow(x, 2) + :math.pow(y, 2))
    direction = %{x: x / distance, y: y / distance}

    %{
      direction: direction,
      distance: distance
    }
  end

  defp player_within_visible_players?(bot_player, player_id) do
    {:player, aditional_info} = bot_player.aditional_info
    Enum.member?(aditional_info.visible_players, player_id)
  end

  defp determine_player_move_action(bot_player, direction) do
    {:player, aditional_info} = bot_player.aditional_info

    if Map.has_key?(aditional_info.cooldowns, @dash_skill_key) do
      {:move, maybe_run_away(aditional_info, direction)}
    else
      {:use_skill, @dash_skill_key, maybe_run_away(aditional_info, direction)}
    end
  end

  defp maybe_run_away(bot_player_info, direction) do
    health_percentage = bot_player_info.health * 100 / bot_player_info.max_health

    if health_percentage < 30 do
      Vector.mult(direction, -1)
    else
      direction
    end
  end

  defp detemine_player_attack(bot_player, closest_player, config) do
    {:player, aditional_info} = bot_player.aditional_info

    character = Enum.find(config.characters, fn character -> character.name == aditional_info.character_name end)
    skill_1 = Map.get(character.skills, @skill_1_key)
    skill_2 = Map.get(character.skills, @skill_2_key)

    cond do
      aditional_info.available_stamina != 0 and closest_player.distance <= skill_1.targetting_radius ->
        {:use_skill_1, @skill_1_key, closest_player.direction}

      not Map.has_key?(aditional_info.cooldowns, @skill_2_key) and closest_player.distance <= skill_2.targetting_radius ->
        {:use_skill_2, @skill_2_key, closest_player.direction}

      true ->
        {:attack, closest_player.direction}
    end
  end
end
