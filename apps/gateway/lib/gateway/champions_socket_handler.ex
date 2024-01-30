defmodule Gateway.ChampionsSocketHandler do
  @moduledoc """
  Module that handles cowboy websocket requests
  """

  require Logger

  @behaviour :cowboy_websocket

  @impl true
  def init(req, _opts) do
    client_id = :cowboy_req.binding(:client_id, req)

    {:cowboy_websocket, req, %{client_id: client_id}}
  end

  @impl true
  def websocket_init(state) do
    Logger.info("Websocket INIT called")

    {:reply, {:pong, ""}, state}
  end

  def websocket_handle({:binary, message}, state) do
    case Serialization.GameAction.decode(message) do
      %{action_type: {:attack, %{skill: skill}}} ->
        GameUpdater.attack(state.game_pid, state.player_id, skill)

      %{action_type: {:move, %{direction: direction}}, timestamp: timestamp} ->
        GameUpdater.move(
          state.game_pid,
          state.player_id,
          {direction.x, direction.y},
          timestamp
        )

      _ ->
        {}
    end

    {:ok, state}
  end

  @impl true
  def websocket_handle(message, state) do
    Logger.info("You should not be here: #{inspect(message)}")
    {:reply, {:text, "error"}, state}
  end

  # # Send a ping frame every once in a while
  # @impl true
  # def websocket_info(:send_ping, state) do
  #   Process.send_after(self(), :send_ping, @ping_interval_ms)
  #   time_now = Time.utc_now()
  #   {:reply, :ping, Map.put(state, :last_ping_time, time_now)}
  # end

  # @impl true
  # def websocket_info({:game_update, game_state}, state) do
  #   # Logger.info("Websocket info, Message: GAME UPDATE")
  #   {:reply, {:binary, game_state}, state}
  # end

  # @impl true
  # def websocket_info({:game_finished, game_state}, state) do
  #   # Logger.info("Websocket info, Message: GAME FINISHED")
  #   {:reply, {:binary, game_state}, state}
  # end

  @impl true
  def websocket_info(message, state) do
    Logger.info("You should not be here: #{inspect(message)}")
    {:reply, {:binary, Jason.encode!(%{})}, state}
  end
end
