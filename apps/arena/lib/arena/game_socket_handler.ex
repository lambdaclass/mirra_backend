defmodule Arena.GameSocketHandler do
  @moduledoc """
  Module that handles cowboy websocket requests
  """
  require Logger
  alias Arena.GameUpdater

  @behaviour :cowboy_websocket

  @impl true
  def init(req, _opts) do
    player_id = :cowboy_req.binding(:player_id, req)
    game_id = :cowboy_req.binding(:game_id, req)
    game_pid = game_id |> Base58.decode() |> :erlang.binary_to_term([:safe])

    {:cowboy_websocket, req, %{player_id: player_id, game_pid: game_pid, game_id: game_id}}
  end

  @impl true
  def websocket_init(state) do
    Phoenix.PubSub.subscribe(Arena.PubSub, state.game_id)
    Logger.info("Websocket INIT called")
    {:reply, {:binary, Jason.encode!(%{})}, state}
  end

  @impl true
  def websocket_handle(:ping, state) do
    Logger.info("Websocket PING handler")
    {:reply, {:pong, ""}, state}
  end

  def websocket_handle({:binary, message}, state) do
    case Arena.Protobuf.GameAction.decode(message) do
      %{action_type: {:attack, %{skill: skill}}} ->
        GameUpdater.attack(state.game_pid, state.player_id, skill)

      %{action_type: {:move, %{direction: direction}}} ->
        GameUpdater.move(state.game_pid, state.player_id, {direction.x, direction.y})

      _ ->
        {}
    end

    {:reply, {:binary, Jason.encode!(%{})}, state}
  end

  @impl true
  def websocket_info({:game_update, game_state}, state) do
    # Logger.info("Websocket info, Message: GAME UPDATE")
    {:reply, {:binary, game_state}, state}
  end

  @impl true
  def websocket_info(_message, state) do
    # Logger.info("Websocket info, Message: #{inspect(message)}")
    {:reply, {:binary, Jason.encode!(%{})}, state}
  end
end
