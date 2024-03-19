defmodule BotManager.SocketHandler do
  @moduledoc """
  BotManager entrypoint websocket handler.
  It handles the communication with the server as a new client.
  """
  use WebSockex, restart: :transient
  require Logger
  alias BotManager.BotSupervisor
  alias BotManager.Protobuf

  def start_link(%{"client_id" => client_id}) do
    Logger.info("Client INIT #{client_id}")
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
    game_id = Protobuf.GameState.decode(game_state).game_id
    Logger.info("Client joining game with id: #{game_id}")

    BotSupervisor.add_bot_to_game(
      state.client_id,
      game_id
    )

    {:ok, state}
  end

  @impl true
  def terminate({:remote, 1000, ""}, _state) do
    Logger.info("Client websocket terminated with {:remote, 1000} status")
    exit(:normal)
  end

  # Private
  defp ws_url(player_id) do
    host = "localhost:4000"
    character = "h4ck"

    case System.get_env("SSL_ENABLED") do
      "true" ->
        "wss://#{host}/join/#{player_id}/#{character}/#{player_id}"

      _ ->
        "ws://#{host}/join/#{player_id}/#{character}/#{player_id}"
    end
  end
end
