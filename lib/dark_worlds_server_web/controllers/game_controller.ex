defmodule DarkWorldsServerWeb.GameController do
  use DarkWorldsServerWeb, :controller

  alias DarkWorldsServer.Communication
  alias DarkWorldsServer.RunnerSupervisor

  def current_games(conn, _params) do
    current_games_pids = RunnerSupervisor.list_runners_pids()

    current_games =
      Enum.map(current_games_pids, fn pid -> Communication.pid_to_external_id(pid) end)

    json(conn, %{current_games: current_games})
  end

  def player_game(conn, %{"player_id" => _player_id}) do
    json(conn, %{ongoing_game: false})
  end
end
