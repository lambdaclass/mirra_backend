defmodule Arena.GameSocketHandler do
  @moduledoc """
  Module that handles cowboy websocket requests
  """
  require Logger
  alias Arena.Serialization
  alias Arena.GameUpdater
  alias Arena.Serialization.{GameEvent, GameJoined, PingUpdate}

  @behaviour :cowboy_websocket

  @ping_interval_ms 500

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

    {:ok, %{player_id: player_id, game_config: config}} = GameUpdater.join(state.game_pid, state.client_id)

    state =
      Map.put(state, :player_id, player_id)
      |> Map.put(:enable, false)
      |> Map.put(:block_actions, false)

    encoded_msg =
      GameEvent.encode(%GameEvent{
        event: {:joined, %GameJoined{player_id: player_id, config: to_broadcast_config(config)}}
      })

    Process.send_after(self(), :send_ping, @ping_interval_ms)

    {:reply, {:binary, encoded_msg}, state}
  end

  @impl true
  def websocket_handle(_, %{enable: false} = state) do
    {:ok, state}
  end

  @impl true
  def websocket_handle(_, %{block_actions: true} = state) do
    {:ok, state}
  end

  @impl true
  def websocket_handle(:pong, state) do
    last_ping_time = state.last_ping_time
    time_now = Time.utc_now()
    latency = Time.diff(time_now, last_ping_time, :millisecond)

    encoded_msg =
      GameEvent.encode(%GameEvent{
        event: {:ping, %PingUpdate{latency: latency}}
      })

    # Send back the player's ping
    {:reply, {:binary, encoded_msg}, state}
  end

  def websocket_handle(:ping, state) do
    {:reply, {:pong, ""}, state}
  end

  def websocket_handle({:binary, message}, state) do
    case Serialization.GameAction.decode(message) do
      %{action_type: {:attack, %{skill: skill, parameters: params}}, timestamp: timestamp} ->
        GameUpdater.attack(state.game_pid, state.player_id, skill, params, timestamp)

      %{action_type: {:use_item, _}, timestamp: timestamp} ->
        GameUpdater.use_item(state.game_pid, state.player_id, timestamp)

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

  # Send a ping frame every once in a while
  @impl true
  def websocket_info(:send_ping, state) do
    Process.send_after(self(), :send_ping, @ping_interval_ms)
    time_now = Time.utc_now()
    {:reply, :ping, Map.put(state, :last_ping_time, time_now)}
  end

  # Enable incomming messages
  @impl true
  def websocket_info(:enable_incomming_messages, state) do
    {:ok, Map.put(state, :enable, true)}
  end

  @impl true
  def websocket_info({:game_update, game_state}, state) do
    # Logger.info("Websocket info, Message: GAME UPDATE")
    {:reply, {:binary, game_state}, state}
  end

  @impl true
  def websocket_info({:game_finished, game_state}, state) do
    # Logger.info("Websocket info, Message: GAME FINISHED")
    {:reply, {:binary, game_state}, state}
  end

  @impl true
  def websocket_info({:player_dead, player_id}, state) do
    if state.player_id == player_id do
      {:ok, Map.put(state, :enable, false)}
    else
      {:ok, state}
    end
  end

  @impl true
  def websocket_info({:block_actions, player_id, value}, state) do
    if state.player_id == player_id do
      {:ok, Map.put(state, :block_actions, value)}
    else
      {:ok, state}
    end
  end

  @impl true
  def websocket_info(message, state) do
    Logger.info("You should not be here: #{inspect(message)}")
    {:reply, {:binary, Jason.encode!(%{})}, state}
  end

  defp to_broadcast_config(config) do
    %{config | characters: Enum.map(config.characters, &to_broadcast_character/1)}
  end

  defp to_broadcast_character(character) do
    %{character | skills: Map.new(character.skills, &to_broadcast_skill/1)}
  end

  defp to_broadcast_skill({key, skill}) do
    ## TODO: This will break once a skill has more than 1 mechanic, until then
    ##   we can use this "shortcut" and deal with it when the time comes
    [{_mechanic, params}] = skill.mechanics
    extra_params = %{targetting_radius: params[:range], targetting_angle: params[:angle]}
    {key, Map.merge(skill, extra_params)}
  end
end
