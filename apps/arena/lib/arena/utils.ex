defmodule Arena.Utils do
  @moduledoc """
  Utils module.
  It contains utility functions like math functions.
  """

  def normalize(%{x: 0, y: 0}) do
    %{x: 0, y: 0}
  end

  def normalize(%{x: x, y: y}) do
    length = :math.sqrt(x * x + y * y)
    %{x: x / length, y: y / length}
  end

  def increase_value_by_base_percentage(current_value, base_value, amount) when is_integer(current_value) do
    (current_value + base_value * amount)
    |> round()
  end

  def increase_value_by_base_percentage(current_value, base_value, amount) do
    current_value + base_value * amount
  end

  def get_bot_connection_url(game_id, bot_client) do
    server_url = System.get_env("PHX_HOST") || "localhost"
    bot_manager_host = System.get_env("BOT_MANAGER_HOST", "localhost:4003")
    protocol = get_correct_protocol(bot_manager_host)

    "#{protocol}#{bot_manager_host}/join/#{server_url}/#{game_id}/#{bot_client}"
  end

  defp get_correct_protocol("localhost" <> _host), do: "http://"
  defp get_correct_protocol(_host), do: "https://"

  def assign_teams_to_players(players, :pair) do
    Enum.chunk_every(players, 2)
    |> Enum.with_index(fn player_pair, index ->
      Enum.map(player_pair, fn player -> Map.put(player, :team, index) end)
    end)
    |> List.flatten()
  end

  def assign_teams_to_players(players, :solo) do
    Enum.with_index(players, fn player, index ->
      Map.put(player, :team, index)
    end)
  end

  def assign_teams_to_players(players, _not_implemented), do: players
end
