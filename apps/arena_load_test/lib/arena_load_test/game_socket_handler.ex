defmodule ArenaLoadTest.GameSocketHandler do
  @moduledoc """
  ArenaLoadTest in-game websocket handler.
  It handles the communication with the server as a player.
  """
  alias ArenaLoadTest.SocketSupervisor
  alias ArenaLoadTest.Serialization
  use WebSockex, restart: :transient
  require Logger

  def start_link({client_id, game_id}) do
    Logger.info("Player INIT")
    ws_url = ws_url(client_id, game_id)

    WebSockex.start_link(
      ws_url,
      __MODULE__,
      %{
        client_id: client_id,
        game_id: game_id
      },
      debug: [:trace]
    )
  end

  # Callbacks
  def handle_frame({_type, _msg} = _frame, state) do
    # Logger.info("Received frame with msg: #{_msg}")
    {:ok, state}
  end

  def handle_info(:move, state) do
    Logger.info("Sending GameAction frame with MOVE payload")

    {x, y} = create_random_movement()
    timestamp = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

    game_action =
      Serialization.GameAction.encode(%Serialization.GameAction{
        action_type:
          {:move,
           %Serialization.Move{
             direction: %Serialization.Direction{
               x: x,
               y: y
             }
           }},
        timestamp: timestamp
      })

    WebSockex.cast(self(), {:send, {:binary, game_action}})

    Process.send_after(self(), :move, 500, [])
    {:ok, state}
  end

  def handle_info(:attack, state) do
    Logger.info("Sending GameAction frame with ATTACK payload")
    timestamp = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
    {x, y} = create_random_movement()

    game_action =
      Serialization.GameAction.encode(%Serialization.GameAction{
        action_type:
          {:attack,
           %Serialization.Attack{
             skill: "1",
             parameters: %Serialization.AttackParameters{
              target: %Serialization.Direction{
                x: x,
                y: y
              }
             }
           }},
        timestamp: timestamp
      })

    WebSockex.cast(self(), {:send, {:binary, game_action}})

    Process.send_after(self(), :attack, 300, [])
    {:ok, state}
  end

  def handle_cast({:send, {_type, _msg} = frame}, state) do
    # Logger.info("Sending frame with payload: #{msg}")
    {:reply, frame, state}
  end

  # Private
  defp create_random_movement() do
    Enum.random([
      {1, 0},
      {0, -1},
      {-1, 0},
      {0, 1}
    ])
  end

  defp ws_url(client_id, game_id) do
    host = SocketSupervisor.server_host()

    case System.get_env("SSL_ENABLED") do
      "true" ->
        "wss://#{host}/play/#{game_id}/#{client_id}"

      _ ->
        "ws://#{host}/play/#{game_id}/#{client_id}"
    end
  end
end
