defmodule Arena.Matchmaking do
  @moduledoc """
  Module that handles matchmaking queues
  """
  def get_queue("battle-royale"), do: Arena.Matchmaking.GameLauncher
  def get_queue("pair"), do: Arena.Matchmaking.PairMode
  def get_queue("quick-game"), do: Arena.Matchmaking.QuickGameMode
  def get_queue("deathmatch"), do: Arena.Matchmaking.DeathmatchMode
  def get_queue(:undefined), do: Arena.Matchmaking.GameLauncher
end
