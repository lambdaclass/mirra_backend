defmodule BotManager.GameSocketHandler do
  @moduledoc """
  BotManager socket handler.
  It handles the communication with the server.
  """

  alias BotManager.BotStateMachine

  use WebSockex, restart: :transient
  require Logger

  @decision_delay_ms 200
  @action_delay_ms 30

  def start_link(%{"bot_client" => bot_client, "game_id" => game_id} = params) do
    ws_url = ws_url(params) |> IO.inspect(label: "conectarse a ")

    WebSockex.start_link(ws_url, __MODULE__, %{
      client_id: bot_client,
      game_id: game_id
    })
  end

  #######################
  #      handlers       #
  #######################

  def handle_connect(_conn, state) do
    send(self(), :decide_action)
    send(self(), :perfom_action)
    {:ok, state}
  end

  def handle_frame({:binary, frame}, state) do
    case BotManager.Protobuf.GameEvent.decode(frame) do
      %{event: {:update, game_state}} ->
        bot_player = Map.get(game_state.players, state.player_id)

        update = %{
          bot_player: bot_player,
          game_state: game_state
        }

        {:ok, Map.merge(state, update)}

      %{event: {:joined, joined}} ->
        {:ok, Map.merge(state, joined)}

      %{event: {:finished, _}} ->
        {:stop, state}

      _ ->
        {:ok, state}
    end
  end

  def handle_info(:decide_action, state) do
    Process.send_after(self(), :decide_action, @decision_delay_ms)

    action = BotStateMachine.decide_action(state)

    {:ok, Map.put(state, :current_action, action)}
  end

  def handle_info(:perfom_action, state) do
    Process.send_after(self(), :perfom_action, @action_delay_ms)

    send_current_action(state)

    {:ok, state}
  end

  def handle_cast({:send, {_type, _msg} = frame}, state) do
    {:reply, frame, state}
  end

  defp send_current_action(%{current_action: {:move, direction}}) do
    timestamp = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

    game_action =
      BotManager.Protobuf.GameAction.encode(%BotManager.Protobuf.GameAction{
        action_type:
          {:move,
           %BotManager.Protobuf.Move{
             direction: %BotManager.Protobuf.Direction{
               x: direction.x,
               y: direction.y
             }
           }},
        timestamp: timestamp
      })

    WebSockex.cast(self(), {:send, {:binary, game_action}})
  end

  defp send_current_action(%{current_action: {:attack, direction}}) do
    timestamp = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

    game_action =
      BotManager.Protobuf.GameAction.encode(%BotManager.Protobuf.GameAction{
        action_type:
          {:attack,
           %BotManager.Protobuf.Attack{
             skill: "1",
             parameters: %BotManager.Protobuf.AttackParameters{
               target: %BotManager.Protobuf.Direction{
                 x: direction.x,
                 y: direction.y
               }
             }
           }},
        timestamp: timestamp
      })

    WebSockex.cast(self(), {:send, {:binary, game_action}})
  end

  defp send_current_action(_), do: nil

  def terminate(_, _, _) do
    exit(:normal)
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
end
