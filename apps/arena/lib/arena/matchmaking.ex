defmodule Arena.Matchmaking do
  @moduledoc """
  Module that handles matchmaking queues
  """
  def get_queue("battle-royale"), do: Arena.Matchmaking.GameLauncher
  def get_queue("duo"), do: Arena.Matchmaking.DuoMode
  def get_queue("trio"), do: Arena.Matchmaking.TrioMode
  def get_queue("quick-game"), do: Arena.Matchmaking.QuickGameMode
  def get_queue("deathmatch"), do: Arena.Matchmaking.DeathmatchMode
  def get_queue(:undefined), do: Arena.Matchmaking.GameLauncher

  def get_matchmaking_configuration(matchmaking_state, team_size, game_mode_type) do
    if Map.has_key?(matchmaking_state, :game_mode_configuration) do
      matchmaking_state
    else
      case Arena.Configuration.get_game_mode_configuration(team_size, game_mode_type) do
        {:error, _} ->
          matchmaking_state

        {:ok, game_mode_configuration} ->
          map = Enum.random(game_mode_configuration.map_mode_params)

          Map.put(matchmaking_state, :game_mode_configuration, game_mode_configuration)
          |> Map.put(:current_map, map)
      end
    end
  end
end
