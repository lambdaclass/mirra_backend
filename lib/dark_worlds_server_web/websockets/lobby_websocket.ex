defmodule DarkWorldsServerWeb.LobbyWebsocket do
  require Logger

  alias DarkWorldsServer.Communication
  alias DarkWorldsServer.Matchmaking.MatchingCoordinator

  @behaviour :cowboy_websocket

  @impl true
  def init(req, _opts) do
    [{"user_id", user_id}] = :cowboy_req.parse_qs(req)
    {:cowboy_websocket, req, %{user_id: user_id}}
  end

  @impl true
  def websocket_init(%{user_id: user_id}) do
    :ok = MatchingCoordinator.join(user_id)
    ## TODO: Remove this once the old lobby screen is removed
    send(self(), {:player_added, 1, user_id, 1, [{1, user_id}]})
    {:reply, {:binary, Communication.lobby_connected!(user_id, 1, "player_name")}, %{user_id: user_id}}
  end

  @impl true
  def websocket_handle(_, state) do
    {:ok, state}
  end

  @impl true
  def websocket_info({:player_added, player_id, player_name, host_player_id, players}, state) do
    {:reply, {:binary, Communication.lobby_player_added!(player_id, player_name, host_player_id, players)}, state}
  end

  def websocket_info({:notify_players_amount, amount_of_players, capacity}, state) do
    {:reply, {:binary, Communication.notify_player_amount!(amount_of_players, capacity)}, state}
  end

  def websocket_info({:game_started, game_pid, game_config}, state) do
    new_state = Map.put(state, :game_started, true)
    server_hash = Application.get_env(:dark_worlds_server, :information) |> Keyword.get(:version_hash)

    reply_map = %{
      game_pid: game_pid,
      game_config: game_config,
      server_hash: server_hash
    }

    {:reply, {:binary, Communication.lobby_game_started!(reply_map)}, new_state}
  end

  @impl true
  def terminate(reason, _partialreq, %{user_id: user_id}) do
    log_termination(reason)
    MatchingCoordinator.leave(user_id)
    :ok
  end

  def terminate(reason, _req, _state) do
    log_termination(reason)

    :ok
  end

  defp log_termination({_, 1000, _} = reason) do
    Logger.info("#{__MODULE__} with PID #{inspect(self())} closed with message: #{inspect(reason)}")
  end

  defp log_termination(reason) do
    Logger.error("#{__MODULE__} with PID #{inspect(self())} terminated with error: #{inspect(reason)}")
  end
end
