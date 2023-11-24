defmodule LoadTest.LobbyPlayer do
  @config_folder "../../client/Assets/StreamingAssets/"
  @doc """
  A socket representing a player inside a lobby
  """
  use WebSockex, restart: :transient
  require Logger
  use Tesla

  alias LoadTest.Communication.Proto.LobbyEvent
  alias LoadTest.Communication.Proto.GameConfig
  alias LoadTest.Communication.Proto.BoardSize
  alias LoadTest.PlayerSupervisor

  def characters_config() do
    @config_folder
    |> then(fn folder -> folder <> "Characters.json" end)
    |> then(&File.read!/1)
    |> Jason.decode!(keys: :atoms)
  end

  def start_link({player_number, lobby_id, max_duration}) do
    ws_url = ws_url(lobby_id)

    WebSockex.start_link(ws_url, __MODULE__, %{
      player_number: player_number,
      lobby_id: lobby_id,
      max_duration: max_duration
    })
  end

  def handle_frame({_type, msg}, state) do
    case LobbyEvent.decode(msg) do
      %LobbyEvent{type: :GAME_STARTED, game_id: game_id} ->
        {:ok, pid} =
          PlayerSupervisor.spawn_game_player(state.player_number, game_id, state.max_duration)

        Process.send(pid, :play, [])
        {:close, {1000, ""}, state}

      _ ->
        {:ok, state}
    end
  end

  def handle_cast({:send, {_type, _msg} = frame}, state) do
    # Logger.info("Sending frame with payload: #{msg}")
    {:reply, frame, state}
  end

  def start_game(player_pid) do
    runner_config = %{
      board_width: 1000,
      board_height: 1000,
      server_tickrate_ms: 30,
      game_timeout_ms: 1_200_000
    }

    start_game_command = %LobbyEvent{
      type: :START_GAME,
      game_config: %{
        runner_config: runner_config,
        character_config: characters_config()
      }
    }

    WebSockex.cast(player_pid, {:send, {:binary, LobbyEvent.encode(start_game_command)}})
  end

  defp ws_url(lobby_id) do
    host = PlayerSupervisor.server_host()

    case System.get_env("SSL_ENABLED") do
      "true" ->
        "wss://#{host}/matchmaking/#{lobby_id}"

      _ ->
        "ws://#{host}/matchmaking/#{lobby_id}"
    end
  end
end
