defmodule Arena.GameSocketHandler do
  @moduledoc """
  Module that handles cowboy websocket requests
  """
  require Logger
  alias Arena.Serialization
  alias Arena.GameUpdater
  alias Arena.Serialization.GameEvent
  alias Arena.Serialization.GameJoined

  @behaviour :cowboy_websocket

  @impl true
  def init(req, _opts) do
    client_id = :cowboy_req.binding(:client_id, req)
    game_id = :cowboy_req.binding(:game_id, req)
    game_pid = game_id |> Base58.decode() |> :erlang.binary_to_term([:safe])

    {:cowboy_websocket, req, %{client_id: client_id, game_pid: game_pid, game_id: game_id}}
  end

  @impl true
  def websocket_init(state) do
    Logger.info("Websocket INIT called")
    Phoenix.PubSub.subscribe(Arena.PubSub, state.game_id)

    {:ok, %{player_id: player_id, game_config: config}} =
      GameUpdater.join(state.game_pid, state.client_id)

    state = Map.put(state, :player_id, player_id)

    encoded_msg =
      GameEvent.encode(%GameEvent{
        event: {:joined, %GameJoined{player_id: player_id, config: config}}
      })

    {:reply, {:binary, encoded_msg}, state}
  end

  @impl true
  def websocket_handle(:ping, state) do
    Logger.info("Websocket PING handler")
    {:reply, {:pong, ""}, state}
  end

  def websocket_handle({:binary, message}, state) do
    case Serialization.GameAction.decode(message) do
      %{action_type: {:attack, %{skill: skill}}} ->
        GameUpdater.attack(state.game_pid, state.player_id, skill)

      %{action_type: {:move, %{direction: direction}}, timestamp: timestamp} ->
        GameUpdater.move(state.game_pid, state.player_id, {direction.x, direction.y}, timestamp)

      _ ->
        {}
    end

    {:ok, state}
  end

  @impl true
  def websocket_info({:game_event, game_state}, state) do
    # Logger.info("Websocket info, Message: GAME UPDATE")
    {:reply, {:binary, game_state}, state}
  end

  @impl true
  def websocket_info(_message, state) do
    # Logger.info("Websocket info, Message: #{inspect(message)}")
    {:reply, {:binary, Jason.encode!(%{})}, state}
  end
end
