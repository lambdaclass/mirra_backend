defmodule DarkWorldsServerWeb.GameController do
  use DarkWorldsServerWeb, :controller

  alias DarkWorldsServer.Communication
  # alias DarkWorldsServer.Communication.Proto.CharacterConfig
  # alias DarkWorldsServer.Communication.Proto.CharacterConfigItem
  # alias DarkWorldsServer.Communication.Proto.RunnerConfig
  # alias DarkWorldsServer.Communication.Proto.SkillConfigItem
  # alias DarkWorldsServer.Communication.Proto.SkillsConfig
  alias DarkWorldsServer.RunnerSupervisor
  # alias DarkWorldsServer.RunnerSupervisor.PlayerTracker
  # alias DarkWorldsServer.RunnerSupervisor.Runner

  def current_games(conn, _params) do
    current_games_pids = RunnerSupervisor.list_runners_pids()

    current_games =
      Enum.map(current_games_pids, fn pid -> Communication.pid_to_external_id(pid) end)

    json(conn, %{current_games: current_games})
  end

  def player_game(conn, %{"player_id" => _player_id}) do
    json(conn, %{ongoing_game: false})
    # case PlayerTracker.get_player_game(player_id) do
    #   nil ->
    #     json(conn, %{ongoing_game: false})

    #   {game_pid, game_player_id} ->
    #     {
    #       game_status,
    #       player_count,
    #       selected_characters,
    #       %{game_config: game_config}
    #      } = Runner.get_game_state(game_pid)

    #     selections = Enum.map(selected_characters, fn {id, name} -> %{character_name: name, id: id} end)
    #     game_config = Enum.reduce(game_config, %{}, &transform_config/2)
    #     server_hash = Application.get_env(:dark_worlds_server, :information) |> Keyword.get(:version_hash)

    #     json(conn, %{
    #       ongoing_game: game_status != :game_finished,
    #       on_character_selection: game_status == :character_selection,
    #       # We add 1 because when the reconnect happens it will increase by 1
    #       player_count: player_count + 1,
    #       server_hash: server_hash,
    #       current_game_id: Communication.pid_to_external_id(game_pid),
    #       current_game_player_id: game_player_id,
    #       players: selections,
    #       game_config: game_config
    #     })
    # end
  end

  # defp transform_config({:runner_config, config}, acc) do
  #   do_transform_config(:runner_config, config, RunnerConfig, acc)
  # end

  # defp transform_config({:character_config, config}, acc) do
  #   do_transform_config(:character_config, config, CharacterConfig, CharacterConfigItem, acc)
  # end

  # defp transform_config({:skills_config, config}, acc) do
  #   do_transform_config(:skills_config, config, SkillsConfig, SkillConfigItem, acc)
  # end

  # defp transform_config({:__unknown_fields__, _}, acc) do
  #   acc
  # end

  # defp do_transform_config(key, config, config_struct, acc) do
  #   {:ok, character_config} =
  #     struct!(config_struct, config)
  #     |> Protobuf.JSON.encode()

  #   Map.put(acc, key, character_config)
  # end

  # defp do_transform_config(key, config, config_struct, config_item_struct, acc) do
  #   items = Enum.map(config[:Items], &struct!(config_item_struct, &1))
  #   config = Map.put(config, :Items, items)

  #   do_transform_config(key, config, config_struct, acc)
  # end
end
