defmodule DarkWorldsServer.Communication do
  alias DarkWorldsServer.Communication.Proto.GameAction
  alias DarkWorldsServer.Communication.Proto.GameEvent
  alias DarkWorldsServer.Communication.Proto.GameFinished
  alias DarkWorldsServer.Communication.Proto.GameStarted
  alias DarkWorldsServer.Communication.Proto.GameState
  alias DarkWorldsServer.Communication.Proto.LobbyEvent
  alias DarkWorldsServer.Communication.Proto.Move
  alias DarkWorldsServer.Communication.Proto.OldGameEvent
  alias DarkWorldsServer.Communication.Proto.PlayerInformation
  alias DarkWorldsServer.Communication.Proto.TransitionGameEvent
  alias DarkWorldsServer.Communication.Proto.UseInventory
  alias DarkWorldsServer.Communication.Proto.UseSkill

  @moduledoc """
  The Communication context
  """

  def lobby_connected!(lobby_id, player_id, player_name) do
    player_info = %PlayerInformation{player_id: player_id, player_name: player_name}

    %LobbyEvent{type: :CONNECTED, lobby_id: lobby_id, player_info: player_info}
    |> LobbyEvent.encode()
  end

  def lobby_player_added!(player_id, player_name, host_player_id, players) do
    player_info = %PlayerInformation{player_id: player_id, player_name: player_name}

    players_info =
      Enum.map(players, fn {id, name} -> %PlayerInformation{player_id: id, player_name: name} end)

    %LobbyEvent{
      type: :PLAYER_ADDED,
      added_player_info: player_info,
      host_player_id: host_player_id,
      players_info: players_info
    }
    |> LobbyEvent.encode()
  end

  def lobby_preparing_game!(%{
        game_pid: game_pid,
        game_config: game_config,
        server_hash: server_hash
      }) do
    game_id = pid_to_external_id(game_pid)

    %LobbyEvent{
      type: :PREPARING_GAME,
      game_id: game_id,
      game_config: game_config,
      server_hash: server_hash
    }
    |> LobbyEvent.encode()
  end

  def notify_player_amount!(amount_of_players, capacity) do
    %LobbyEvent{
      type: :NOTIFY_PLAYER_AMOUNT,
      amount_of_players: amount_of_players,
      capacity: capacity
    }
    |> LobbyEvent.encode()
  end

  def game_started!(new_game_state, old_game_state, usernames, player_timestamp, server_timestamp) do
    old_game_event = %OldGameEvent{
      type: :GAME_STARTED,
      players: old_game_state.players,
      projectiles: old_game_state.projectiles,
      killfeed: old_game_state.killfeed,
      playable_radius: old_game_state.playable_radius,
      shrinking_center: old_game_state.shrinking_center,
      loots: old_game_state.loots,
      player_timestamp: player_timestamp,
      server_timestamp: server_timestamp,
      usernames: usernames
    }

    new_game_event = %GameEvent{
      event:
        {:game_started,
         %GameStarted{
           starting_state: %GameState{
             players: Map.values(new_game_state.players),
             projectiles: new_game_state.projectiles,
             items: new_game_state.loots,
             zone_info: new_game_state.zone,
             killfeed: new_game_state.killfeed,
             player_timestamp: player_timestamp,
             server_timestamp: server_timestamp
           }
         }}
    }

    %TransitionGameEvent{old_game_event: old_game_event, new_game_event: new_game_event}
    |> TransitionGameEvent.encode()
  end

  def game_update!(new_game_state, old_game_state, player_timestamp, server_timestamp) do
    old_game_event = %OldGameEvent{
      type: :STATE_UPDATE,
      players: old_game_state.players,
      projectiles: old_game_state.projectiles,
      killfeed: old_game_state.killfeed,
      playable_radius: old_game_state.playable_radius,
      shrinking_center: old_game_state.shrinking_center,
      loots: old_game_state.loots,
      player_timestamp: player_timestamp,
      server_timestamp: server_timestamp
    }

    new_game_event = %GameEvent{
      event:
        {:game_state,
         %GameState{
           players: Map.values(new_game_state.players),
           projectiles: new_game_state.projectiles,
           items: new_game_state.loots,
           zone_info: new_game_state.zone,
           killfeed: new_game_state.killfeed,
           player_timestamp: player_timestamp,
           server_timestamp: server_timestamp
         }}
    }

    %TransitionGameEvent{old_game_event: old_game_event, new_game_event: new_game_event}
    |> TransitionGameEvent.encode()
  end

  def encode!(%{latency: latency}) do
    old_game_event = %OldGameEvent{type: :PING_UPDATE, latency: latency}

    %TransitionGameEvent{old_game_event: old_game_event}
    |> TransitionGameEvent.encode()
  end

  def game_finished!(new_winner, new_players, old_winner, old_players) do
    old_game_event = %OldGameEvent{type: :GAME_FINISHED, winner_player: old_winner, players: old_players}

    new_game_event = %GameEvent{
      event: {:game_finished, %GameFinished{winner: new_winner, players: Map.values(new_players)}}
    }

    %TransitionGameEvent{old_game_event: old_game_event, new_game_event: new_game_event}
    |> TransitionGameEvent.encode()
  end

  def game_player_joined(player_id, player_name) do
    old_game_event = %OldGameEvent{type: :PLAYER_JOINED, player_joined_id: player_id, player_joined_name: player_name}

    %TransitionGameEvent{old_game_event: old_game_event}
    |> TransitionGameEvent.encode()
  end

  def joined_game(player_id) do
    old_game_event = %OldGameEvent{type: :PLAYER_JOINED, player_joined_id: player_id}

    %TransitionGameEvent{old_game_event: old_game_event}
    |> TransitionGameEvent.encode()
  end

  def player_move(angle) do
    %GameAction{timestamp: timestamp(), action_type: {:move, %Move{angle: angle}}}
    |> GameAction.encode()
  end

  def player_use_skill(skill, angle) do
    %GameAction{
      timestamp: timestamp(),
      action_type: {:use_skill, %UseSkill{skill: skill, angle: angle, auto_aim: false}}
    }
    |> GameAction.encode()
  end

  def player_use_inventory(inventory_at) do
    %GameAction{timestamp: timestamp(), action_type: {:use_inventory, %UseInventory{inventory_at: inventory_at}}}
    |> GameAction.encode()
  end

  def decode(value) do
    try do
      {:ok, GameAction.decode(value)}
    rescue
      Protobuf.DecodeError -> {:error, :error_decoding}
    end
  end

  def pid_to_external_id(pid) when is_pid(pid) do
    pid |> :erlang.term_to_binary() |> Base58.encode()
  end

  def external_id_to_pid(external_id) do
    external_id |> Base58.decode() |> :erlang.binary_to_term([:safe])
  end

  def pubsub_game_topic(game_pid) when is_pid(game_pid) do
    "game_play_#{pid_to_external_id(game_pid)}"
  end

  defp timestamp() do
    DateTime.utc_now() |> DateTime.to_unix(:millisecond)
  end
end
