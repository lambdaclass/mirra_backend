defmodule GameClient.ClientSocketHandler do
  @moduledoc """
  GameClient socket handler.
  It handles the communication with the server.
  """

  alias GameClient.Serialization.ConversionProtobuf

  use WebSockex, restart: :transient
  require Logger

  def start_link(live_pid, gateway_jwt, player_id, game_id) do
    ws_url = ws_url(gateway_jwt, player_id, game_id)

    WebSockex.start_link(ws_url, __MODULE__, %{
      player_id: player_id,
      live_pid: live_pid,
      game_id: game_id
    })
  end

  def handle_frame({:binary, game_event}, state) do
    # Logger.info("Received Message: GAME EVENT")
    Process.send(state.live_pid, {:game_event, game_event}, [])
    {:ok, state}
  end

  def handle_info({:move, %{"x" => x, "y" => y}}, state) do
    Logger.info("Sending GameAction frame with MOVE payload")

    timestamp = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
    game_action = ConversionProtobuf.get_game_move_protobuf(x, y, timestamp)

    {:reply, {:binary, game_action}, state}
  end

  def handle_info({:attack, skill}, state) do
    Logger.info("Sending GameAction frame with ATTACK payload")

    timestamp = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
    game_action = ConversionProtobuf.get_game_attack_protobuf(skill, 0, 0, timestamp)

    {:reply, {:binary, game_action}, state}
  end

  def handle_info({:use_item, item}, state) do
    Logger.info("Sending GameAction frame with USE_ITEM payload")

    game_action = ConversionProtobuf.get_game_use_item_protobuf(item)

    {:reply, {:binary, game_action}, state}
  end

  def handle_info(:toggle_bots, state) do
    Logger.info("Sending GameAction frame with toggle_bots payload")

    game_action = ConversionProtobuf.get_toggle_bots_protobuf()

    {:reply, {:binary, game_action}, state}
  end

  def handle_info(:close, state) do
    Logger.info("ClientSocket closed")
    {:close, state}
  end

  defp ws_url(gateway_jwt, player_id, game_id) do
    # FIX ME Remove hardcoded host
    host = "localhost:4000"

    case System.get_env("SSL_ENABLED") do
      "true" ->
        "wss://#{host}/play/#{game_id}/#{player_id}?gateway_jwt=#{gateway_jwt}"

      _ ->
        "ws://#{host}/play/#{game_id}/#{player_id}?gateway_jwt=#{gateway_jwt}"
    end
  end
end
