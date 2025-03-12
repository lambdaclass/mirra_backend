defmodule Arena.SocketHandler do
  @moduledoc """
  Module that handles cowboy websocket requests
  """
  require Logger
  alias Arena.Authentication.GatewaySigner
  alias Arena.Authentication.GatewayTokenManager
  alias Arena.Matchmaking
  alias Arena.Serialization.GameState
  alias Arena.Serialization.JoinedLobby
  alias Arena.Serialization.LeaveLobby
  alias Arena.Serialization.LeftLobby
  alias Arena.Serialization.LobbyEvent

  @behaviour :cowboy_websocket

  @impl true
  def init(req, _opts) do
    # TODO: We need to mock user_id validation for bots (loadtests are broken).
    # Ideally we could have JWT that says "Bot Server".
    # https://github.com/lambdaclass/mirra_backend/issues/765
    user_id =
      if System.get_env("OVERRIDE_JWT") == "true" do
        :cowboy_req.binding(:client_id, req)
      else
        [{"gateway_jwt", jwt}] = :cowboy_req.parse_qs(req)
        signer = GatewaySigner.get_signer()
        {:ok, %{"sub" => user_id}} = GatewayTokenManager.verify_and_validate(jwt, signer)
        user_id
      end

    matchmaking_queue = Matchmaking.get_queue(:cowboy_req.binding(:mode, req))
    player_name = :cowboy_req.binding(:player_name, req)

    {character_name, skin_name} =
      if System.get_env("OVERRIDE_JWT") == "true" do
        {:cowboy_req.binding(:character_name, req), "Basic"}
      else
        gateway_url = Application.get_env(:arena, :gateway_url)
        url = "#{gateway_url}/curse/users/#{user_id}/get_unit"

        {:ok, %{character_name: character_name, skin_name: skin_name}} =
          case Finch.build(:get, url, [{"content-type", "application/json"}])
               |> Finch.request(Arena.Finch) do
            {:ok, payload} ->
              {:ok, Jason.decode!(payload.body, [{:keys, :atoms}])}

            {:error, _} ->
              {:error, %{}}
          end

        {character_name, skin_name}
      end

    {:cowboy_websocket, req,
     %{
       client_id: user_id,
       matchmaking_queue: matchmaking_queue,
       character_name: character_name,
       skin_name: skin_name,
       player_name: player_name
     }}
  end

  @impl true
  def websocket_init(state) do
    Logger.info("Websocket INIT called")
    state.matchmaking_queue.join(state)
    joined_msg = LobbyEvent.encode(%LobbyEvent{event: {:joined, %JoinedLobby{}}})
    {:reply, {:binary, joined_msg}, state}
  end

  @impl true
  def websocket_handle({:binary, message}, state) do
    case LeaveLobby.decode(message) do
      %LeaveLobby{} ->
        :ok = state.matchmaking_queue.leave(state.client_id)
        left_msg = LobbyEvent.encode(%LobbyEvent{event: {:left, %LeftLobby{}}})
        {[{:binary, left_msg}, :close], state}

      _ ->
        {:ok, state}
    end
  end

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
    game = %GameState{game_id: game_id, players: %{}, projectiles: %{}}
    game_msg = LobbyEvent.encode(%LobbyEvent{event: {:game, game}})
    {:reply, {:binary, game_msg}, state}
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
