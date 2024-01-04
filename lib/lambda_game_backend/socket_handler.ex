defmodule LambdaGameBackend.SocketHandler do
  @moduledoc """
  Module that handles cowboy websocket requests
  """
  require Logger
  alias LambdaGameBackend.GameUpdater

  @behaviour :cowboy_websocket

  @impl true
  def init(req, _opts) do
    player_id = :cowboy_req.binding(:player_id, req)

    game_pid =
      case Process.whereis(GameUpdater) do
        nil ->
          {:ok, pid} = GenServer.start_link(GameUpdater, %{player_id: player_id}, name: GameUpdater)
          pid

        game_pid ->
          GameUpdater.join(game_pid, player_id)
          game_pid
      end

    {:cowboy_websocket, req, %{game_pid: game_pid, player_id: player_id}}
  end

  @impl true
  def websocket_init(state) do
    Logger.info("Websocket INIT called")
    {:reply, {:binary, Jason.encode!(%{})}, state}
  end

  @impl true
  def websocket_handle(:ping, state) do
    Logger.info("Websocket PING handler")
    {:reply, {:pong, ""}, state}
  end

  def websocket_handle({:binary, message}, state) do
    direction = LambdaGameBackend.Protobuf.Direction.decode(message)

    GameUpdater.move(state.game_pid, state.player_id, {direction.x, direction.y})

    {:reply, {:binary, Jason.encode!(%{})}, state}
  end

  @impl true
  def websocket_info(message, state) do
    Logger.info("Websocket info, Message: #{inspect(message)}")
    {:reply, {:binary, Jason.encode!(%{})}, state}
  end
end
