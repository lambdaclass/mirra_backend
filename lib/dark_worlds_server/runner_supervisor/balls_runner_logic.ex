defmodule DarkWorldsServer.RunnerSupervisor.BallsRunnerLogic do
  alias DarkWorldsServer.Communication.Proto.Move
  alias DarkWorldsServer.Communication.Proto.UseInventory
  alias DarkWorldsServer.Communication.Proto.UseSkill
  alias DarkWorldsServer.RunnerUtils

  def perform_action(state, {:move, user_id, %Move{angle: angle}, timestamp}) when angle in [0.0, 180.0] do
    player_id = state.user_to_player[user_id] || user_id
    game_state = GameBackend.move_player(state.game_state, player_id, angle + 90 * (player_id - 1))

    Map.put(state, :game_state, game_state)
    |> put_in([:player_timestamps, user_id], timestamp)
  end

  def perform_action(state, {:use_skill, user_id, %UseSkill{skill: skill} = use_skill, timestamp}) do
    player_id = state.user_to_player[user_id] || user_id
    skill_key = RunnerUtils.action_skill_to_key(skill)
    skill_params = RunnerUtils.extract_and_convert_params(use_skill)
    game_state = GameBackend.activate_skill(state.game_state, player_id, skill_key, skill_params)

    Map.put(state, :game_state, game_state)
    |> put_in([:player_timestamps, user_id], timestamp)
  end

  def perform_action(state, {:use_inventory, user_id, %UseInventory{inventory_at: inventory_at}, timestamp}) do
    player_id = state.user_to_player[user_id] || user_id

    game_state =
      GameBackend.activate_inventory(state.game_state, player_id, inventory_at)

    Map.put(state, :game_state, game_state)
    |> put_in([:player_timestamps, user_id], timestamp)
  end

  def perform_action(state, _), do: state
end
