defmodule Arena.Matchmaking do
  @moduledoc """
  Module that handles matchmaking queues
  """

  def get_queue("battle-royal"), do: Arena.Matchmaking.GameLauncher
  def get_queue(:undefined), do: Arena.Matchmaking.GameLauncher
end
