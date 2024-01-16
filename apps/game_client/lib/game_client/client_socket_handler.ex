defmodule GameClient.ClientSocketHandler do
  use WebSockex, restart: :transient
  require Logger

  def start_link(live_pid, player_id, game_id) do
    ws_url = ws_url(player_id, game_id)

    WebSockex.start_link(ws_url, __MODULE__, %{
      player_id: player_id,
      live_pid: live_pid,
      game_id: game_id
    })
  end

  def handle_frame({:binary, game_event}, state) do
    # Logger.info("Received Message: GAME EVENT")
    Process.send(state.live_pid |> :erlang.list_to_pid(), {:game_event, game_event}, [])
    {:ok, state}
  end

  def handle_info({:move, %{"x" => x, "y" => y}}, state) do
    Logger.info("Sending GameAction frame with MOVE payload")

    game_action =
      GameClient.Protobuf.GameAction.encode(%GameClient.Protobuf.GameAction{
        action_type:
          {:move,
           %GameClient.Protobuf.Move{
             direction: %GameClient.Protobuf.Direction{
               x: x,
               y: y
             }
           }}
      })

    {:reply, {:binary, game_action}, state}
  end

  def handle_info({:attack, skill}, state) do
    Logger.info("Sending GameAction frame with ATTACK payload")

    game_action =
      GameClient.Protobuf.GameAction.encode(%GameClient.Protobuf.GameAction{
        action_type: {:attack, %GameClient.Protobuf.Attack{skill: skill}}
      })

    {:reply, {:binary, game_action}, state}
  end

  defp ws_url(player_id, game_id) do
    # TODO Remove hardcoded host
    host = "localhost:4000"

    case System.get_env("SSL_ENABLED") do
      "true" ->
        "wss://#{host}/play/#{game_id}/#{player_id}"

      _ ->
        "ws://#{host}/play/#{game_id}/#{player_id}"
    end
  end
end
