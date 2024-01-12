# defmodule GameClient.GameSocketHandler do
#   @moduledoc """
#   Module that handles cowboy websocket requests
#   """
#   require Logger
#   alias GameClient.GameUpdater

#   @behaviour :cowboy_websocket

#   @impl true
#   def init(req, _opts) do
#     player_id = :cowboy_req.binding(:player_id, req)
#     game_pid = :cowboy_req.binding(:game_id, req) |> Base58.decode() |> :erlang.binary_to_term([:safe])

#     {:cowboy_websocket, req, %{player_id: player_id, game_pid: game_pid}}
#   end

#   @impl true
#   def websocket_init(state) do
#     Logger.info("Websocket INIT called")
#     {:reply, {:binary, Jason.encode!(%{})}, state}
#   end

#   @impl true
#   def websocket_handle(:ping, state) do
#     Logger.info("Websocket PING handler")
#     {:reply, {:pong, ""}, state}
#   end

#   def websocket_handle({:binary, message}, state) do
#     case GameClient.Protobuf.GameAction.decode(message) do
#       %{action_type: {:attack, %{skill: skill}}} ->
#         GameUpdater.attack(state.game_pid, state.player_id, skill)

#       %{action_type: {:move, %{direction: direction}}} ->
#         GameUpdater.move(state.game_pid, state.player_id, {direction.x, direction.y})

#       _ ->
#         {}
#     end

#     {:reply, {:binary, Jason.encode!(%{})}, state}
#   end

#   @impl true
#   def websocket_info(message, state) do
#     Logger.info("Websocket info, Message: #{inspect(message)}")
#     {:reply, {:binary, Jason.encode!(%{})}, state}
#   end
# end
