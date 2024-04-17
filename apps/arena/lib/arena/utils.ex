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

  def get_bot_connection_url(game_id, bot_client) do
    server_url = System.get_env("PHX_HOST") || "localhost"
    bot_manager_host = System.get_env("BOT_MANAGER_HOST", "localhost")
    bot_manager_port = System.get_env("BOT_MANAGER_PORT", "4003")

    "http://#{bot_manager_host}:#{bot_manager_port}/join/#{server_url}/#{game_id}/#{bot_client}"
  end
end
