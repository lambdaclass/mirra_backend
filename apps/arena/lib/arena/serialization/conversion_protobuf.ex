defmodule Arena.Serialization.ConversionProtobuf do
  alias Arena.Serialization.{
    GameActionPB,
    GameEventPB,
    GameJoinedPB,
    PingUpdatePB,
    ToggleBotsPB,
    GameStatePB,
    LeaveLobbyPB,
    LobbyEventPB,
    JoinedLobbyPB,
    LeftLobbyPB,
    PingPB,
    PingUpdatePB
  }

  def decode_game_message(message) do
    GameActionPB.decode(message)
  end

  def decode_lobby_message(message) do
    case LeaveLobbyPB.decode(message) do
      %LeaveLobbyPB{} -> :leave_lobby
      _ -> :error
    end
  end

  def get_left_lobby_protobuf() do
    LobbyEventPB.encode(%LobbyEventPB{event: {:left, %LeftLobbyPB{}}})
  end

  def get_lobby_join_game_protobuf(game_id) do
    LobbyEventPB.encode(%LobbyEventPB{event: {:game, %GameStatePB{game_id: game_id, players: %{}, projectiles: %{}}}})
  end

  def get_lobby_joined_lobby_protobuf() do
    LobbyEventPB.encode(%LobbyEventPB{event: {:joined, %JoinedLobbyPB{}}})
  end

  def get_game_game_joined_protobuf(%{player_id: player_id, config: config, bounties: bounties}) do
    GameEventPB.encode(%GameEventPB{
      event: {:joined, %GameJoinedPB{player_id: player_id, config: config, bounties: bounties}}
    })
  end

  def get_game_ping_update_protobuf(latency) do
    GameEventPB.encode(%GameEventPB{
      event: {:ping, %PingUpdatePB{latency: latency}}
    })
  end

  def get_game_toggle_bots_protobuf() do
    GameEventPB.encode(%GameEventPB{
      event: {:toggle_bots, %ToggleBotsPB{}}
    })
  end

  def get_game_update_protobuf(state) do
    GameEventPB.encode(%GameEventPB{
      event:
        {:update,
         %GameStatePB{
           game_id: state.game_id,
           players: state.players,
           projectiles: state.projectiles,
           power_ups: state.power_ups,
           pools: state.pools,
           bushes: state.bushes,
           items: state.items,
           server_timestamp: state.server_timestamp,
           player_timestamps: state.player_timestamps,
           zone: state.zone,
           killfeed: state.killfeed,
           damage_taken: state.damage_taken,
           damage_done: state.damage_done,
           status: state.status,
           start_game_timestamp: state.start_game_timestamp,
           obstacles: state.obstacles,
           crates: state.crates,
           traps: state.traps
         }}
    })
  end

  def get_game_ended_protobuf(state) do
    GameEventPB.encode(%GameEventPB{event: {:finished, state}})
  end

  def get_pong_protobuf(latency) do
    GameEventPB.encode(%GameEventPB{
        event: {:ping_update, %PingUpdatePB{latency: latency}}
      })
  end

  def get_game_ping_protobuf(now) do
    GameEventPB.encode(%GameEventPB{
        event: {:ping, %PingPB{timestamp_now: now}}
      })
  end
end
