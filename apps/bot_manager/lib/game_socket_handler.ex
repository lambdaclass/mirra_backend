defmodule BotManager.GameSocketHandler do
  @moduledoc """
  BotManager socket handler.
  It handles the communication with the server.
  """

  use WebSockex, restart: :transient
  require Logger

  @message_delay_ms 300

  def start_link(%{"bot_client" => bot_client, "game_id" => game_id} = params) do
    ws_url = ws_url(params)

    WebSockex.start_link(ws_url, __MODULE__, %{
      client_id: bot_client,
      game_id: game_id
    })
  end

  def handle_connect(_conn, state) do
    send(self(), :move)
    send(self(), :attack)
    {:ok, state}
  end

  def handle_frame(_frame, state) do
    {:ok, state}
  end

  def handle_info(:move, state) do
    timestamp = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
    {x, y} = create_random_direction()

    game_action =
      BotManager.Protobuf.GameAction.encode(%BotManager.Protobuf.GameAction{
        action_type:
          {:move,
           %BotManager.Protobuf.Move{
             direction: %BotManager.Protobuf.Direction{
               x: x,
               y: y
             }
           }},
        timestamp: timestamp
      })

    WebSockex.cast(self(), {:send, {:binary, game_action}})

    Process.send_after(self(), :move, @message_delay_ms)

    {:ok, state}
  end

  def handle_info(:attack, state) do
    timestamp = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
    {x, y} = create_random_direction()

    game_action =
      BotManager.Protobuf.GameAction.encode(%BotManager.Protobuf.GameAction{
        action_type:
          {:attack,
           %BotManager.Protobuf.Attack{
             skill: "1",
             parameters: %BotManager.Protobuf.AttackParameters{
               target: %BotManager.Protobuf.Direction{
                 x: x,
                 y: y
               }
             }
           }},
        timestamp: timestamp
      })

    WebSockex.cast(self(), {:send, {:binary, game_action}})

    Process.send_after(self(), :attack, @message_delay_ms)
    {:ok, state}
  end

  def handle_cast({:send, {_type, _msg} = frame}, state) do
    {:reply, frame, state}
  end

  def terminate(_, _, _) do
    Logger.info("Websocket terminated")
    :ok
  end

  defp ws_url(%{
         "bot_client" => bot_client,
         "game_id" => game_id,
         "arena_host" => arena_host
       }) do
    Logger.info("Connecting bot with client: #{bot_client} to game: #{game_id} in the server: #{arena_host}")

    if arena_host == "localhost" do
      "ws://localhost:4000/play/#{game_id}/#{bot_client}"
    else
      "wss://#{arena_host}/play/#{game_id}/#{bot_client}"
    end
  end

  defp create_random_direction() do
    Enum.random([
      {1, 0},
      {0, -1},
      {-1, 0},
      {0, 1}
    ])
  end
end
