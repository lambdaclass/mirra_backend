defmodule ArenaLoadTest.SocketHandler do
  @moduledoc """
  ArenaLoadTest entrypoint websocket handler.
  It handles the communication with the server as a new client.
  """
  use WebSockex, restart: :transient
  require Logger
  alias ArenaLoadTest.Serialization
  alias ArenaLoadTest.SocketSupervisor

  def start_link(client_id) do
    Logger.info("Client INIT")
    ws_url = ws_url(client_id)

    WebSockex.start_link(
      ws_url,
      __MODULE__,
      %{
        client_id: client_id
      }
    )
  end

  # Callbacks

  # Game hasn't started yet
  @impl true
  def handle_frame({:binary, ""}, state) do
    Logger.info("Client waiting for game to join")
    {:ok, state}
  end

  @impl true
  def handle_frame({:binary, game_state}, state) do
    game_id = Serialization.GameState.decode(game_state).game_id
    Logger.info("Client joining game with id: #{game_id}")

    {:ok, pid} =
      SocketSupervisor.add_new_player(
        state.client_id,
        game_id
      )

    Process.send(pid, :move, [])
    Process.send(pid, :attack, [])

    {:ok, state}
  end

  @impl true
  def terminate({:remote, 1000, ""}, _state) do
    Logger.info("Client websocket terminated with {:remote, 1000} status")
    exit(:normal)
  end

  # Private
  defp ws_url(player_id) do
    host = SocketSupervisor.server_host()
    # TODO must replace character with a random available one.
    # TODO this will be done as part of https://github.com/lambdaclass/mirra_backend/issues/361
    character = "h4ck"
    player_name = "Player_#{player_id}"

    case System.get_env("SSL_ENABLED") do
      "true" ->
        "wss://#{host}/join/#{player_id}/#{character}/#{player_name}"

      _ ->
        "ws://#{host}/join/#{player_id}/#{character}/#{player_name}"
    end
  end
end
