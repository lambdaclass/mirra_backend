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

  def start_link({player_number, max_duration_seconds, client_event_rate}) do
    player_id = "user_#{player_number}"
    ws_url = ws_url(player_id)

    WebSockex.start_link(ws_url, __MODULE__, %{
      user_id: player_id,
      player_id: player_id,
      player_number: player_number,
      max_duration_seconds: max_duration_seconds,
      client_event_rate: client_event_rate
    })
  end

  def handle_frame({_type, msg}, state) do
    case LobbyEvent.decode(msg) do
      %LobbyEvent{
        type: :PREPARING_GAME,
        game_id: game_id,
        game_config: _config,
        server_hash: _server_hash
      } ->
        {:ok, pid} =
          PlayerSupervisor.spawn_game_player(
            state.player_number,
            game_id,
            state.max_duration_seconds,
            state.client_event_rate
          )

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

  defp ws_url(player_id) do
    host = PlayerSupervisor.server_host()

    case System.get_env("SSL_ENABLED") do
      "true" ->
        "wss://#{host}/matchmaking?user_id=#{player_id}"

      _ ->
        "ws://#{host}/matchmaking?user_id=#{player_id}"
    end
  end
end
