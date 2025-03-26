defmodule Arena.Bots.Bot do
  @moduledoc """
  Arena bot GenServer.
  This module is in charge of handling bots messages to the Game process.
  """
  use GenServer
  alias Phoenix.PubSub
  alias Arena.Bots.PathfindingGrid
  alias BotManager.BotStateMachine
  alias BotManager.BotStateMachineChecker
  require Logger
  @action_delay_ms 30

  def start_link(%{bot_id: bot_id, game_id: _game_id} = params) do
    GenServer.start_link(__MODULE__, params, name: generate_bot_name(bot_id))
  end

  def init(%{bot_id: bot_id, game_id: game_id}) do
    game_pid = game_id |> Base58.decode() |> :erlang.binary_to_term([:safe])
    PubSub.subscribe(Arena.PubSub, "BOTS_#{game_id}")
    send(self(), :decide_action)
    send(self(), :perform_action)

    {:ok,
     %{
       bot_id: bot_id,
       game_pid: game_pid,
       attack_blocked: false,
       bot_state_machine: BotStateMachineChecker.new(),
       enabled?: true,
       current_action: %{}
     }}
  end

  def handle_info(:decide_action, state) do
    Process.send_after(self(), :decide_action, Enum.random(min_decision_delay_ms()..max_decision_delay_ms()))
    %{action: action, bot_state_machine: bot_state_machine} = BotStateMachine.decide_action(state)
    {:noreply, %{state | current_action: %{action: action, sent: false}, bot_state_machine: bot_state_machine}}
  end

  def handle_info(:perform_action, state) do
    Process.send_after(self(), :perform_action, @action_delay_ms)
    send_current_action(state)
    {:noreply, update_block_attack_state(state)}
  end

  def handle_info(:unblock_attack, state) do
    {:noreply, %{state | attack_blocked: false}}
  end

  def handle_info({:game_update, game_state, config}, state) do
    state = maybe_update_state_params(state, game_state, config)

    case game_state.status do
      :RUNNING ->
        updated_state = update_bot_state(state, game_state)
        {:noreply, updated_state}

      :ENDED ->
        {:stop, :shutdown, state}

      _ ->
        {:noreply, state}
    end
  end

  def handle_info({:enable_bots, enable_bots?}, state) do
    {:noreply, Map.put(state, :enabled?, enable_bots?)}
  end

  def handle_info({:collision_grid_response, grid}, state) do
    {:noreply, %{state | bot_state_machine: %{state.bot_state_machine | collision_grid: grid}}}
  end

  defp maybe_update_state_params(state, game_state, config) do
    if System.get_env("PATHFINDING_TEST") == "true" and is_nil(state.bot_state_machine.collision_grid) do
      PathfindingGrid.get_map_collision_grid(config.map.name, self())
    end

    state
    |> Map.put_new(:config, config)
    |> Map.put_new(:bot_player_id, get_in(game_state, [:client_to_player_map, state.bot_id]))
  end

  defp generate_bot_name(bot_id), do: {:via, Registry, {BotRegistry, bot_id}}

  defp update_bot_state(state, game_state) do
    bot_player = Map.get(game_state.players, state.bot_player_id)

    state =
      if Map.has_key?(state, :bot_skills) do
        state
      else
        {:player, aditional_info} = bot_player.aditional_info

        skills =
          BotManager.Utils.list_character_skills_from_config(
            aditional_info.character_name,
            state.config.characters
          )

        Map.put(state, :bot_skills, skills)
      end

    bot_state_machine =
      if is_nil(state.bot_state_machine.is_melee) do
        Map.put(state.bot_state_machine, :is_melee, state.bot_skills.basic.attack_type == :MELEE)
      else
        state.bot_state_machine
      end

    update = %{
      bot_player: bot_player,
      game_state: game_state,
      bot_state_machine: bot_state_machine
    }

    Map.merge(state, update)
  end

  defp update_block_attack_state(%{current_action: %{action: {:use_skill, _, _}, sent: false}} = state) do
    Process.send_after(self(), :unblock_attack, 100)
    %{state | attack_blocked: true, current_action: %{state.current_action | sent: true}}
  end

  defp update_block_attack_state(state), do: state

  defp send_current_action(%{current_action: %{action: {:move, direction}, sent: false}} = state) do
    timestamp = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
    Arena.GameUpdater.move(state.game_pid, state.bot_player.id, direction, timestamp)
  end

  defp send_current_action(%{current_action: %{action: {:use_skill, skill_key, direction}, sent: false}} = state) do
    timestamp = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
    Arena.GameUpdater.attack(state.game_pid, state.bot_player.id, skill_key, %{target: direction}, timestamp)
  end

  defp send_current_action(_), do: nil

  def terminate(reason, state) do
    Logger.error("Bot #{state.bot_id} terminating: #{inspect(reason)}")
  end

  defp min_decision_delay_ms(), do: if(System.get_env("PATHFINDING_TEST") == "true", do: 100, else: 750)
  defp max_decision_delay_ms(), do: if(System.get_env("PATHFINDING_TEST") == "true", do: 150, else: 1250)
end
