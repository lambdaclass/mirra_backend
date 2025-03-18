defmodule Arena.Bots.Bot do
  @moduledoc """
  Arena bot instance.
  """
  use GenServer
  alias BotManager.BotStateMachine
  alias BotManager.BotStateMachineChecker
  require Logger
  @action_delay_ms 30

  def start_link(%{bot_id: bot_id, game_id: _game_id} = params) do
    IO.inspect("starteando botardo2")

    GenServer.start_link(__MODULE__, params, name: via_tuple(bot_id) |> IO.inspect()) |> IO.inspect()
  end

  defp via_tuple(bot_id), do: {:via, Registry, {BotRegistry, bot_id}}

  def init(%{bot_id: bot_id, game_id: game_id}) do
    IO.inspect("starteando botardo 3")

    send(self(), :decide_action)
    send(self(), :perform_action)
    {:ok, %{bot_id: bot_id, game_id: game_id, attack_blocked: false, bot_state_machine: BotStateMachineChecker.new(), bots_enabled?: true, current_action: %{}}}
  end

  def init(params) do
    IO.inspect(params)
  end

  def handle_info(:decide_action, state) do
    # IO.inspect("voy a decidir una acción")
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

  def handle_cast({:game_event, game_event}, state) do
    case game_event do
      %{event: {:update, game_state}} ->
        bot_player = Map.get(game_state.players, state.bot_id)
        updated_state = update_bot_state(state, bot_player, game_state)
        {:noreply, updated_state}

      %{event: {:joined, joined}} ->
        {:noreply, Map.merge(state, joined)}

      %{event: {:finished, _}} ->
        {:stop, :shutdown, state}

      %{event: {:toggle_bots, _}} ->
        {:noreply, %{state | bots_enabled?: not state.bots_enabled?}}

      _ ->
        {:noreply, state}
    end
  end

  defp update_bot_state(state, bot_player, game_state) do
    bot_state_machine = if is_nil(state.bot_state_machine.is_melee) do
      %{state.bot_state_machine | is_melee: bot_player.attack_type == :MELEE}
    else
      state.bot_state_machine
    end

    %{state | bot_player: bot_player, game_state: game_state, bot_state_machine: bot_state_machine}
  end

  defp update_block_attack_state(%{current_action: %{action: {:use_skill, _, _}, sent: false}} = state) do
    Process.send_after(self(), :unblock_attack, 100)
    %{state | attack_blocked: true, current_action: %{state.current_action | sent: true}}
  end

  defp update_block_attack_state(state), do: state

  defp send_current_action(%{current_action: %{action: {:move, direction}, sent: false}} = state) do
    timestamp = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
    Logger.info("Bot #{state.bot_id} moving in direction: #{inspect(direction)} at #{timestamp}")
  end

  defp send_current_action(%{current_action: %{action: {:use_skill, skill_key, direction}, sent: false}} = state) do
    timestamp = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
    Logger.info("Bot #{state.bot_id} using skill #{skill_key} towards #{inspect(direction)} at #{timestamp}")
  end

  defp send_current_action(_), do: nil

  def terminate(reason, state) do
    Logger.error("Bot #{state.bot_id} terminating: #{inspect(reason)}")
  end

  defp min_decision_delay_ms(), do: (if System.get_env("PATHFINDING_TEST") == "true", do: 100, else: 750)
  defp max_decision_delay_ms(), do: (if System.get_env("PATHFINDING_TEST") == "true", do: 150, else: 1250)
end
