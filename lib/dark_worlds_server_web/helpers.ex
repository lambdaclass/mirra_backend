defmodule DarkWorldsServerWeb.Helpers do
  alias DarkWorldsServer.Communication
  alias DarkWorldsServer.Engine

  def order_players_by_health(players) do
    players
    |> Enum.sort_by(fn player -> player.health end, :desc)
    |> Enum.with_index()
  end

  def alive_players(players) do
    players
    |> Enum.filter(fn player -> is_alive?(player) end)
  end

  def is_alive?(%{status: :alive}), do: true
  def is_alive?(_), do: false

  def list_game_sessions() do
    Engine.list_runners_pids()
    |> Enum.map(fn pid -> Communication.pid_to_external_id(pid) end)
  end
end
