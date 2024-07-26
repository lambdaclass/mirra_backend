defmodule Arena.SocketHandler do
  @moduledoc """
  Module that handles cowboy websocket requests
  """
  require Logger
  alias Arena.Authentication.GatewaySigner
  alias Arena.Authentication.GatewayTokenManager
  alias Arena.GameLauncher
  alias Arena.Serialization.ConversionProtobuf

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

    character_name = :cowboy_req.binding(:character_name, req)
    player_name = :cowboy_req.binding(:player_name, req)
    {:cowboy_websocket, req, %{client_id: user_id, character_name: character_name, player_name: player_name}}
  end

  @impl true
  def websocket_init(state) do
    Logger.info("Websocket INIT called")
    GameLauncher.join(state.client_id, state.character_name, state.player_name)

    message = ConversionProtobuf.get_lobby_joined_lobby_protobuf()
    {:reply, {:binary, message}, state}
  end

  @impl true
  def websocket_handle({:binary, message}, state) do
    decoded_message = ConversionProtobuf.decode_lobby_message(message)

    case decoded_message do
      :leave_lobby ->
        :ok = GameLauncher.leave(state.client_id)
        message = ConversionProtobuf.get_left_lobby_protobuf()
        {[{:binary, message}, :close], state}

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
    message = ConversionProtobuf.get_lobby_join_game_protobuf(game_id)
    {:reply, {:binary, message}, state}
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
