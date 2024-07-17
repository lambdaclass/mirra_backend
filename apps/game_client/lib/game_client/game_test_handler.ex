defmodule GameTestHandler do
  @moduledoc """
  GameClient socket handler.
  It handles the communication with the server.
  """

  use WebSockex, restart: :transient
  require Logger
  alias Arena.Serialization

  def start_link(gateway_jwt, player_id, game_id) do
    ws_url = ws_url(gateway_jwt, player_id, game_id)

    WebSockex.start_link(ws_url, __MODULE__, %{})
  end

  def handle_connect(_, state) do
    Logger.info("Game connected")
    {:ok, state}
  end

  def handle_frame({:binary, event}, state) do
    decoded = Serialization.GameEvent.decode(event)
    case decoded.event do
      {:update, game_update} ->
        Logger.info("Received update", %{server_timestamp: game_update.server_timestamp, status: game_update.status})
        {:ok, state}
      _ ->
        {:ok, state}
    end
  end

  def terminate(close_reason, _state) do
    Logger.info("Game socket closed: #{inspect(close_reason)}")
    :ok
  end

  defp ws_url(gateway_jwt, player_id, game_id) do
    # FIX ME Remove hardcoded host
    # host = "localhost:4000"
    host = "arena-brazil-testing.curseofmirra.com"
    "wss://#{host}/play/#{game_id}/#{player_id}?gateway_jwt=#{gateway_jwt}"
  end
end
