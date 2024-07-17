defmodule TestHandler do
  @moduledoc """
  GameClient socket handler.
  It handles the communication with the server.
  """

  use WebSockex, restart: :transient
  require Logger
  alias Arena.Serialization

  @gateway_jwt "eyJhbGciOiJFZDI1NTE5IiwidHlwIjoiSldUIn0.eyJkZXYiOiJhaUJWOTN1NkhBdmpJV3h2R2plQWlrTXVuM0xURVBwcmhMelFMb1VOR0ljPSIsImV4cCI6MTcyMTIxNDA0OSwiaWF0IjoxNzIxMjA2ODQ5LCJqdGkiOiIydmhmOTBsc3FoNmxhNzN1YXMwMDFnN2giLCJuYmYiOjE3MjEyMDY4NDksInN1YiI6IjU1MWJhNzMxLWU2YmUtNDgzNi1hNjk2LTQ5NzE1MDQyMDViMyJ9.dvm3I5PlEiEVIQCtn0C9q1WZVKWpugkuhoPexoNMKeaiGizrAGFP38pVJ-EzgMcLc7HihDUxJVZkYSUGT2xlAw"
  @player_id "551ba731-e6be-4836-a696-4971504205b3"

  def start_link() do
    ws_url = ws_url(@gateway_jwt, @player_id)

    WebSockex.start_link(ws_url, __MODULE__, %{})
  end

  def handle_frame({:binary, event}, state) do
    decoded = Serialization.LobbyEvent.decode(event)
    case decoded.event do
      {:joined, _} ->
        Logger.info("Joined lobby")
        {:ok, state}
      {:game, %{game_id: game_id}} ->
        Logger.info("Moving to game")
        GameTestHandler.start_link(@gateway_jwt, @player_id, game_id)
        {:ok, state}
    end
  end

  def terminate(close_reason, _state) do
    Logger.info("Closing matchmaking socket: #{inspect(close_reason)}")
    :ok
  end

  defp ws_url(gateway_jwt, player_id) do
    # FIX ME Remove hardcoded host
    # host = "localhost:4000"
    host = "arena-brazil-testing.curseofmirra.com"
    "wss://#{host}/join/#{player_id}/muflus/amin?gateway_jwt=#{gateway_jwt}"
  end
end
