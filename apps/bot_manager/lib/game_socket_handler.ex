defmodule BotManager.GameSocketHandler do
  @moduledoc """
  BotManager socket handler.
  It handles the communication with the server.
  """

  use WebSockex, restart: :transient
  require Logger

  def start_link(player_id, game_id) do
    IO.inspect(game_id, label: "aber game_id")
    IO.inspect(player_id, label: "aber player_id")
    ws_url = ws_url(player_id, game_id)

    WebSockex.start_link(ws_url, __MODULE__, %{
      player_id: player_id,
      game_id: game_id
    })
  end

  def handle_info({:move, %{"x" => x, "y" => y}}, state) do
    Logger.info("Sending GameAction frame with MOVE payload")

    game_action =
      BotManager.Protobuf.GameAction.encode(%BotManager.Protobuf.GameAction{
        action_type:
          {:move,
           %BotManager.Protobuf.Move{
             direction: %BotManager.Protobuf.Direction{
               x: x,
               y: y
             }
           }}
      })

    {:reply, {:binary, game_action}, state}
  end

  defp ws_url(player_id, game_id) do
    # FIX ME Remove hardcoded host
    host = "localhost:3000"

    case System.get_env("SSL_ENABLED") do
      "true" ->
        "wss://#{host}/play/#{game_id}/#{player_id}"

      _ ->
        "ws://#{host}/play/#{game_id}/#{player_id}"
    end
    |> IO.inspect(label: "aber url")
  end
end
