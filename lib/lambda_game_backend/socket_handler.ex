defmodule LambdaGameBackend.SocketHandler do
  @moduledoc """
  Module that handles cowboy websocket requests
  """
  require Logger
  alias LambdaGameBackend.GameLauncher
  alias LambdaGameBackend.Protobuf.GameState

  @behaviour :cowboy_websocket

  @impl true
  def init(req, _opts) do
    player_id = :cowboy_req.binding(:player_id, req)

    {:cowboy_websocket, req, %{player_id: player_id}}
  end

  @impl true
  def websocket_init(state) do
    Logger.info("Websocket INIT called")
    GameLauncher.join(state.player_id)

    game_state =
      GameState.encode(%GameState{
        game_id: nil,
        entities: %{}
      })

    {:reply, {:binary, game_state}, state}
  end

  @impl true
  def websocket_handle(:ping, state) do
    Logger.info("Websocket PING handler")
    {:reply, {:pong, ""}, state}
  end

  @impl true
  def websocket_info(:leave_waiting_game, state) do
    Logger.info("Websocket info, Message: left waiting game")
    {:stop, state}
  end

  @impl true
  def websocket_info({:join_game, game_id}, state) do
    Logger.info("Websocket info, Message: joined game with id: #{inspect(game_id)}")

    game_state =
      GameState.encode(%GameState{
        game_id: game_id,
        entities: %{}
      })

    {:reply, {:binary, game_state}, state}
  end

  @impl true
  def websocket_info(message, state) do
    Logger.info("Websocket info, Message: #{inspect(message)}")
    {:reply, {:binary, Jason.encode!(%{})}, state}
  end

  @impl true
  def terminate(_, _, _) do
    Logger.info("Websocket terminated")
    :ok
  end
end
