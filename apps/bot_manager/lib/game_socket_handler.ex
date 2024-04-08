defmodule BotManager.GameSocketHandler do
  @moduledoc """
  BotManager socket handler.
  It handles the communication with the server.
  """

  use WebSockex, restart: :transient
  require Logger

  @message_delay_ms 300
  @decision_delay_ms 200
  @action_delay_ms 30

  def start_link(%{"bot_client" => bot_client, "game_id" => game_id}) do
    Logger.info("Connecting bot with client: #{bot_client} to game: #{game_id}")
    ws_url = ws_url(bot_client, game_id)

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
        update_map = %{
          game_state: game_state
        }

        {:ok, Map.merge(state, update_map)}

      %{event: {:joined, joined}} ->
        {:ok, Map.merge(state, joined)}

      %{event: {:finished, _}} ->
        {:stop, state}

      _ ->
        {:ok, state}
    end
  end

  def handle_info(:decide_action, %{game_state: game_state} = state) do
    Process.send_after(self(), :decide_action, @decision_delay_ms)
    players_directions = map_directions_to_players(game_state, state.player_id) |> IO.inspect(label: "aber directions")
    state = process_interest_map(state, players_directions)

    {current_interest, _interest_amount} =
      Enum.max_by(state.interest_map, fn {_direction, interest} -> interest end)

    {:ok, Map.put(state, :current_action, {:move, current_interest})}
  end

  def handle_info(:decide_action, state) do
    Process.send_after(self(), :decide_action, @decision_delay_ms)
    {:ok, state}
  end

  def handle_info(:perfom_action, state) do
    Process.send_after(self(), :perfom_action, @action_delay_ms)

    send_current_action(state)

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

  defp send_current_action(_), do: nil

  def terminate(_, _, _) do
    exit(:normal)
  end

  #######################
  #       Helpers       #
  #######################

  defp ws_url(player_id, game_id) do
    host = System.get_env("SERVER_HOST", "localhost:4000")

    case System.get_env("SSL_ENABLED") do
      "true" ->
        "wss://#{host}/play/#{game_id}/#{player_id}"

      _ ->
        "ws://#{host}/play/#{game_id}/#{player_id}"
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

  defp process_interest_map(state, players_directions) do
    interest_map =
      %{
        %{x: 1, y: 0} => 10,
        %{x: 0, y: -1} => 10,
        %{x: -1, y: 0} => 10,
        %{x: 0, y: 1} => 10,
        %{x: -1, y: -1} => 10,
        %{x: 1, y: -1} => 10,
        %{x: -1, y: 1} => 10,
        %{x: 1, y: 1} => 10
      }
      |> Map.new(fn {vector, _interest} ->
        {vector, get_players_interest(vector, players_directions)}
      end)

    # Map.merge(interest_map, players_dots, fn _vector, interest, dot -> interest + dot end)
    # |> IO.inspect(label: "aber interest with dot")

    Map.put(state, :interest_map, interest_map)
  end

  defp map_directions_to_players(game_state, player_id) do
    bot_player = Map.get(game_state.players, player_id)

    Map.delete(game_state.players, player_id)
    |> Map.new(fn {player_id, player} ->
      {player_id, get_ditance_and_direction_to_positions(bot_player.position, player.position)}
    end)
  end

  defp get_ditance_and_direction_to_positions(base_position, end_position) do
    x = end_position.x - base_position.x
    y = end_position.y - base_position.y
    distance = :math.sqrt(:math.pow(x, 2) + :math.pow(y, 2))
    direction = %{x: x / distance, y: y / distance}

    %{
      direction: direction,
      distance: distance
    }
  end

  defp dot_product(base_vector, position) do
    base_vector.x * position.x + base_vector.y * position.y
  end

  defp get_players_interest(vector, players_directions) do
    Enum.map(players_directions, fn {_player_id, players_information} ->
      dot_product(vector, players_information.direction) - players_information.distance
    end)
    |> Enum.sum()
  end
end
