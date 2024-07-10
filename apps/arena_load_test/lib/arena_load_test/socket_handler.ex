defmodule ArenaLoadTest.SocketHandler do
  @moduledoc """
  ArenaLoadTest entrypoint websocket handler.
  It handles the communication with the server as a new client.
  """
  use WebSockex, restart: :transient
  alias ArenaLoadTest.Serialization
  alias ArenaLoadTest.SocketSupervisor
  alias ArenaLoadTest.Utils

  def start_link(client_id) do
    ws_url = ws_url(client_id)

    WebSockex.start_link(
      ws_url,
      __MODULE__,
      %{
        client_id: client_id
      }
    )
  end

  # Callbacks

  # Game hasn't started yet
  @impl true
  def handle_frame({:binary, ""}, state) do
    {:ok, state}
  end

  @impl true
  def handle_frame({:binary, game_state}, state) do
    game_msg = Serialization.LobbyEvent.decode(game_state)

    case game_msg.event do
      {:game, game_state} ->
        game_id = game_state.game_id
        remove_client_from_lobby_ets_table(state.client_id)

        {:ok, pid} =
          SocketSupervisor.add_new_player(
            state.client_id,
            game_id
          )

        true = :ets.insert(:players, {state.client_id, game_id})
        Process.send(pid, :send_action, [])
        {:ok, state}

      {_event, _event_state} ->
        {:ok, state}
    end
  end

  # Private
  defp ws_url(player_id) do
    character = get_random_active_character()
    player_name = "Player_#{player_id}"

    case System.get_env("TARGET_SERVER") do
      nil ->
        "ws://localhost:4000/join/#{player_id}/#{character}/#{player_name}"

      target_server ->
        # TODO Replace this for a SSL connection using erlang credentials.
        # TODO https://github.com/lambdaclass/mirra_backend/issues/493
        "ws://#{Utils.get_server_ip(target_server)}:4000/join/#{player_id}/#{character}/#{player_name}"
    end
  end

  # This is enough for now. Will request bots from the bots app in future iterations.
  # https://github.com/lambdaclass/mirra_backend/issues/410
  defp get_random_active_character() do
    ["muflus", "h4ck", "uma"]
    |> Enum.random()
  end

  defp remove_client_from_lobby_ets_table(client_id) do
    case :ets.lookup(:clients, client_id) do
      [{client_id, _}] ->
        :ets.delete(:clients, client_id)

      [] ->
        raise KeyError, message: "Client with ID #{client_id} doesn't exist."
    end
  end
end
