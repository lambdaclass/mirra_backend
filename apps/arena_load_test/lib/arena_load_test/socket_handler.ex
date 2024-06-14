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
    user_token = create_user(client_id)
    ws_url = ws_url(client_id, user_token)

    WebSockex.start_link(
      ws_url,
      __MODULE__,
      %{
        client_id: client_id,
        user_token: user_token
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
  def handle_frame({:binary, lobby_event}, state) do
    case Serialization.LobbyEvent.decode(lobby_event) do
      %{event: {:game, %{game_id: game_id}}} ->
        case :ets.lookup(:clients, state.client_id) do
          [{client_id, _}] ->
            :ets.delete(:clients, client_id)

          [] ->
            raise KeyError, message: "Client with ID #{state.client_id} doesn't exist."
        end

        {:ok, pid} = SocketSupervisor.add_new_player(state.client_id, state.user_token, game_id)

        true = :ets.insert(:players, {state.client_id, game_id})

        Process.send(pid, :send_action, [])

      _ ->
        :nothing
    end

    {:ok, state}
  end

  # Private
  defp ws_url(player_id, user_token) do
    character = get_random_active_character()
    player_name = "Player_#{player_id}"
    query_params = "gateway_jwt=#{user_token}"

    case System.get_env("TARGET_SERVER") do
      nil ->
        "ws://localhost:4000/join/#{player_id}/#{character}/#{player_name}?#{query_params}"

      target_server ->
        # TODO Replace this for a SSL connection using erlang credentials.
        # TODO https://github.com/lambdaclass/mirra_backend/issues/493
        "ws://#{Utils.get_server_ip(target_server)}:4000/join/#{player_id}/#{character}/#{player_name}?#{query_params}"
    end
  end

  # This is enough for now. Will request bots from the bots app in future iterations.
  # https://github.com/lambdaclass/mirra_backend/issues/410
  defp get_random_active_character() do
    ["muflus", "h4ck", "uma"]
    |> Enum.random()
  end

  defp create_user(client_id) do
    gateway_url = Application.get_env(:arena_load_test, :gateway_url)
    payload = Jason.encode!(%{client_id: to_string(client_id)})

    {:ok, %{status: 200, body: body}} =
      Finch.build(:post, "#{gateway_url}/curse/users", [{"content-type", "application/json"}], payload)
      |> Finch.request(ArenaLoadTest.Finch)

    Jason.decode!(body)
    |> Map.get("gateway_jwt")
  end
end
