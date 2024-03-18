defmodule Arena.SocketHandler do
  @moduledoc """
  Module that handles cowboy websocket requests
  """
  require Logger
  alias Arena.GameLauncher
  alias Arena.Serialization.GameState

  @behaviour :cowboy_websocket

  @impl true
  def init(req, _opts) do
    client_id = :cowboy_req.binding(:client_id, req)
    character_name = :cowboy_req.binding(:character_name, req)
    player_name = :cowboy_req.binding(:player_name, req)
    {:cowboy_websocket, req, %{client_id: client_id, character_name: character_name, player_name: player_name}}
  end

  @impl true
  def websocket_init(state) do
    Logger.info("Websocket INIT called")
    GameLauncher.join(state.client_id, state.character_name, state.player_name)

    game_state =
      GameState.encode(%GameState{
        game_id: nil,
        players: %{},
        projectiles: %{}
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
        players: %{},
        projectiles: %{}
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
