defmodule DarkWorldsServer.Communication do
  alias DarkWorldsServer.Communication.Proto.GameAction
  alias DarkWorldsServer.Communication.Proto.GameEvent
  alias DarkWorldsServer.Communication.Proto.LobbyEvent
  alias DarkWorldsServer.Communication.Proto.PlayerInformation

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

  def lobby_game_started!() do
    %LobbyEvent{
      type: :GAME_STARTED
    }
    |> LobbyEvent.encode()
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
end
