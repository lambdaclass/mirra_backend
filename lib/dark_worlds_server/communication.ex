defmodule DarkWorldsServer.Communication do
  alias DarkWorldsServer.Communication.Proto.GameAction
  alias DarkWorldsServer.Communication.Proto.GameEvent
  alias DarkWorldsServer.Communication.Proto.LobbyEvent
  alias DarkWorldsServer.Communication.Proto.Move
  alias DarkWorldsServer.Communication.Proto.PlayerInformation
  alias DarkWorldsServer.Communication.Proto.UseSkill

  @moduledoc """
  The Communication context
  """

  def lobby_connected!(lobby_id, player_id, player_name) do
    player_info = %PlayerInformation{player_id: player_id, player_name: player_name}

    %LobbyEvent{type: :CONNECTED, lobby_id: lobby_id, player_info: player_info}
    |> LobbyEvent.encode()
  end

  def lobby_player_added!(player_id, player_name, character_name) do
    player_info = %PlayerInformation{player_id: player_id, player_name: player_name, character_name: character_name}

    %LobbyEvent{
      type: :PLAYER_ADDED,
      added_player_info: player_info
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

  def game_started!(%{
        players: players,
        projectiles: projectiles,
        killfeed: killfeed,
        playable_radius: playable_radius,
        shrinking_center: shrinking_center,
        player_timestamp: player_timestamp,
        server_timestamp: server_timestamp,
        loots: loots
      }) do
    %GameEvent{
      type: :GAME_STARTED,
      players: players,
      projectiles: projectiles,
      killfeed: killfeed,
      playable_radius: playable_radius,
      shrinking_center: shrinking_center,
      player_timestamp: player_timestamp,
      server_timestamp: server_timestamp,
      loots: loots
    }
    |> GameEvent.encode()
  end

  def game_update!(%{
        players: players,
        projectiles: projectiles,
        killfeed: killfeed,
        playable_radius: playable_radius,
        shrinking_center: shrinking_center,
        player_timestamp: player_timestamp,
        server_timestamp: server_timestamp,
        loots: loots
      }) do
    %GameEvent{
      type: :STATE_UPDATE,
      players: players,
      projectiles: projectiles,
      killfeed: killfeed,
      playable_radius: playable_radius,
      shrinking_center: shrinking_center,
      player_timestamp: player_timestamp,
      server_timestamp: server_timestamp,
      loots: loots
    }
    |> GameEvent.encode()
  end

  def encode!(%{latency: latency}) do
    %GameEvent{type: :PING_UPDATE, latency: latency}
    |> GameEvent.encode()
  end

  def game_finished!(%{winner: winner, players: players}) do
    %GameEvent{winner_player: winner, type: :GAME_FINISHED, players: players}
    |> GameEvent.encode()
  end

  def game_player_joined(player_id, player_name) do
    %GameEvent{type: :PLAYER_JOINED, player_joined_id: player_id, player_joined_name: player_name}
    |> GameEvent.encode()
  end

  def joined_game(player_id) do
    %GameEvent{type: :PLAYER_JOINED, player_joined_id: player_id}
    |> GameEvent.encode()
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
