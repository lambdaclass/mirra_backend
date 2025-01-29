defmodule BotManager.Utils do
  @moduledoc """
  utils to work with nested game state operations
  """

  alias BotManager.Math.Vector

  def player_alive?(%{aditional_info: {:player, %{health: health}}}), do: health > 0

  def player_alive?(_), do: :not_a_player

  def random_position_within_safe_zone_radius(safe_zone_radius) do
    x = Enum.random(-safe_zone_radius..safe_zone_radius) / 1.0
    y = Enum.random(-safe_zone_radius..safe_zone_radius) / 1.0

    %{x: x, y: y}
  end

  def position_within_radius(position, radius) do
    Vector.distance(%{x: 0, y: 0}, position) <= radius
  end

  # This function will map the directions and distance from the bot to the players.
  def map_directions_to_players(players, bot_player, max_distance) do
    Map.delete(players, bot_player.id)
    |> Map.filter(fn {player_id, player} ->
      player_alive?(player) && player_within_visible_players?(bot_player, player_id) &&
        not bot_belongs_to_the_same_team?(bot_player, player)
    end)
    |> Enum.map(fn {_player_id, player} ->
      player_info =
        get_distance_and_direction_to_positions(bot_player.position, player.position)

      Map.merge(player, player_info)
    end)
    |> Enum.filter(fn player_info -> player_info.distance <= max_distance end)
  end

  def get_distance_and_direction_to_positions(base_position, base_position) do
    %{
      direction: %{x: 0, y: 0},
      distance: 0
    }
  end

  def get_distance_and_direction_to_positions(base_position, end_position) do
    %{x: x, y: y} = Vector.sub(end_position, base_position)

    distance = Vector.norm(%{x: x, y: y})

    direction = Vector.normalize(%{x: x, y: y})

    %{
      direction: direction,
      distance: distance
    }
  end

  defp player_within_visible_players?(bot_player, player_id) do
    {:player, bot_player_info} = bot_player.aditional_info
    Enum.member?(bot_player_info.visible_players, player_id)
  end

  defp bot_belongs_to_the_same_team?(bot_player, player) do
    {:player, bot_player_info} = bot_player.aditional_info
    {:player, player_info} = player.aditional_info

    bot_player_info.team == player_info.team
  end
end
