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
      }
    )
  end

  # Callbacks
  def handle_frame({:binary, msg} = _frame, state) do
    {event_type, _state} = Serialization.GameEvent.decode(msg) |> Map.get(:event)

    if event_type == :finished do
      {:stop, state}
    else
      {:ok, state}
    end
  end

  def handle_info(:move, state) do
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
    timestamp = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
    {x, y} = create_random_movement()

    game_action =
      Serialization.GameAction.encode(%Serialization.GameAction{
        action_type:
          {:attack,
           %Serialization.Attack{
             skill: get_random_available_skill(),
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
    {:reply, frame, state}
  end

  def terminate(_, state) do
    case :ets.lookup(:clients, state.client_id) do
      [{client_id, _}] ->
        :ets.delete(:clients, client_id)

      [] ->
        raise KeyError, message: "Client with ID #{state.client_id} doesn't exist."
    end

    Logger.info("Player websocket terminated. Game Ended.")
    exit(:normal)
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
    case System.get_env("TARGET_SERVER") do
      nil ->
        "ws://localhost:4000/play/#{game_id}/#{client_id}"

      target_server ->
        server_url = SocketSupervisor.get_server_url(target_server)
        "wss://#{server_url}/play/#{game_id}/#{client_id}"
    end
  end

  # This is enough for now. We will get the skills from the requested bots
  # from the bots app. This will be done in future iterations.
  # https://github.com/lambdaclass/mirra_backend/issues/410
  defp get_random_available_skill() do
    ["1", "2", "3"]
    |> Enum.random()
  end
end
