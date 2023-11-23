defmodule LoadTest.PlayerSupervisor do
  @moduledoc """
  Player Supervisor
  """
  use DynamicSupervisor
  use Tesla
  plug(Tesla.Middleware.JSON)
  plug(Tesla.Middleware.Headers, [{"content-type", "application/json"}])

  alias LoadTest.GamePlayer
  alias LoadTest.LobbyPlayer

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def spawn_lobby_player(player_number, lobby_id, max_duration) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {LobbyPlayer, {player_number, lobby_id, max_duration}}
    )
  end

  def spawn_game_player(player_number, game_id, max_duration) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {GamePlayer, {player_number, game_id, max_duration}}
    )
  end

  @impl true
  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  # Creates a lobby, joins a `num_players` to it, then starts the game that lasts `duration` seconds
  def spawn_game(num_players, duration \\ nil) do
    {:ok, response} = get(server_url())
    %{"lobby_id" => lobby_id} = response.body

    {:ok, player_one_pid} = spawn_lobby_player(1, lobby_id, duration)

    for i <- 2..num_players do
      {:ok, _pid} = spawn_lobby_player(i, lobby_id, duration)
    end

    LobbyPlayer.start_game(player_one_pid)
  end

  def n_games_30_players(num_games, duration \\ nil) do
    spawn_games(num_games, 30)
  end

  def one_game_30_players(duration \\ nil) do
    spawn_games(1, 30)
  end

  def spawn_50_sessions(duration \\ nil) do
    spawn_games(50, 3, duration)
  end

  def spawn_games(num_games, num_players, duration \\ nil) do
    for _ <- 1..num_games do
      spawn_game(num_players, duration)
    end
  end

  def children_pids() do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.map(fn {_, pid, _, _} -> pid end)
  end

  def server_host() do
    System.get_env("SERVER_HOST", "localhost:4000")
  end

  defp server_url() do
    host = server_host()

    case System.get_env("SSL_ENABLED") do
      "true" ->
        "https://#{host}/new_lobby"

      _ ->
        "http://#{host}/new_lobby"
    end
  end
end
