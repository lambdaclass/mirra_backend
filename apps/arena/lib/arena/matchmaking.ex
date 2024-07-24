defmodule Arena.Matchmaking do
  @moduledoc """
  Module that handles matchmaking queues
  """

  def get_queue("battle-royal"), do: Arena.GameLauncher
  def get_queue(:undefined), do: Arena.GameLauncher
end
