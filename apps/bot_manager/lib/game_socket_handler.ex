defmodule BotManager.GameSocketHandler do
  @moduledoc """
  BotManager socket handler.
  It handles the communication with the server.
  """

  use WebSockex, restart: :transient
  require Logger

  def start_link(player_id, game_id) do
    ws_url = ws_url(player_id, game_id)

    WebSockex.start_link(ws_url, __MODULE__, %{
      player_id: player_id,
      game_id: game_id
    })
  end

  def handle_info({:move, %{"x" => x, "y" => y}}, state) do
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

    WebSockex.cast(self(), {:send, {:binary, game_action}})

    {:ok, state}
  end

  defp ws_url(player_id, game_id) do
    # FIX ME Remove hardcoded host
    host = "localhost:4000"

    case System.get_env("SSL_ENABLED") do
      "true" ->
        "wss://#{host}/play/#{game_id}/#{player_id}"

      _ ->
        "ws://#{host}/play/#{game_id}/#{player_id}"
    end
  end
end
