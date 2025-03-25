defmodule Arena.Bots.Bot do
  @moduledoc """
  Arena bot GenServer.
  This module is in charge of handling bots messages to the Game process.
  """
  use GenServer
  alias BotManager.BotStateMachine
  alias BotManager.BotStateMachineChecker
  require Logger
  @action_delay_ms 30
  @delay_before_map_grid_building_ms 1000

  def start_link(%{bot_id: bot_id, game_id: _game_id} = params) do
    GenServer.start_link(__MODULE__, params, name: generate_bot_name(bot_id))
  end

  def init(%{bot_id: bot_id, game_id: game_id}) do
    game_pid = game_id |> Base58.decode() |> :erlang.binary_to_term([:safe])
    send(self(), :decide_action)
    send(self(), :perform_action)
    # This delay ensures we give some time to the board liveview to join on time before the game starts.
    # Ideally we should make the collision grid building NIF faster instead of doing this so that we don't have problems
    # running everything on the same machine (for example when testing locally)
    Process.send_after(self(), :allow_map_build, @delay_before_map_grid_building_ms)

    {:ok,
     %{
       bot_id: bot_id,
       game_pid: game_pid,
       attack_blocked: false,
       bot_state_machine: BotStateMachineChecker.new(),
       bots_enabled?: true,
       current_action: %{},
       can_build_map: false
     }}
  end

  @doc """
  Updates the bots state due to new Game event update (new tick) received.
  """
  def update_state(bot_id, game_state, config) do
    GenServer.cast(generate_bot_name(bot_id), {:update_state, game_state, config})
  end

  def handle_info(:allow_map_build, state) do
    {:noreply, Map.put(state, :can_build_map, true)}
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

  def handle_cast({:update_state, game_state, config}, state) do
    case game_state.status do
      :RUNNING ->
        state = maybe_update_state_params(state, game_state, config)
        updated_state = update_bot_state(state, game_state)
        {:noreply, updated_state}

      :ENDED ->
        {:stop, :shutdown, state}

      _ ->
        {:noreply, state}
    end
  end

  defp maybe_update_state_params(state, game_state, config) do
    state
    |> update_in([:config], fn _ -> config end)
    |> update_in([:bot_player_id], fn _ -> get_in(game_state, [:client_to_player_map, state.bot_id]) end)
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
    |> maybe_build_map()
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

  defp maybe_build_map(%{can_build_map: false} = state), do: state
  defp maybe_build_map(%{bot_state_machine: %{collision_grid: collision_grid}} = state) when not is_nil(collision_grid),
    do: state
  defp maybe_build_map(%{game_state: nil} = state), do: state
  defp maybe_build_map(%{game_state: %{obstacles: nil}} = state), do: state
  defp maybe_build_map(%{game_state: %{obstacles: []}} = state), do: state
  defp maybe_build_map(state) do
    obstacles =
      state.game_state.obstacles
      |> Enum.map(fn {obstacle_id, obstacle} ->
        obstacle =
          obstacle
          |> Map.take([
            :id,
            :shape,
            :position,
            :radius,
            :vertices,
            :speed,
            :category,
            :direction,
            :is_moving,
            :name
          ])

        obstacle =
          obstacle
          |> Map.put(:position, %{x: obstacle.position.x, y: obstacle.position.y})
          |> Map.put(
            :vertices,
            Enum.map(obstacle.vertices.positions, fn position -> %{x: position.x, y: position.y} end)
          )
          |> Map.put(:direction, %{x: obstacle.direction.x, y: obstacle.direction.y})
          |> Map.put(:shape, get_shape(obstacle.shape))
          |> Map.put(:category, get_category(obstacle.category))

        {obstacle_id, obstacle}
      end)
      |> Map.new()

    case AStarNative.build_collision_grid(obstacles) do
      {:ok, collision_grid} ->
        update = %{
          bot_state_machine: Map.put(state.bot_state_machine, :collision_grid, collision_grid)
        }

        Map.merge(state, update)

      {:error, reason} ->
        Logger.error("Grid construction failed with reason: #{inspect(reason)}")

        update = %{
          can_build_map: false
        }

        Map.merge(state, update)
    end
  end

  defp get_shape("polygon"), do: :polygon
  defp get_shape("circle"), do: :circle
  defp get_shape("line"), do: :line
  defp get_shape("point"), do: :point
  defp get_shape(_), do: nil

  defp get_category("player"), do: :player
  defp get_category("projectile"), do: :projectile
  defp get_category("obstacle"), do: :obstacle
  defp get_category("power_up"), do: :power_up
  defp get_category("pool"), do: :pool
  defp get_category("item"), do: :item
  defp get_category("bush"), do: :bush
  defp get_category("crate"), do: :crate
  defp get_category("trap"), do: :trap
  defp get_category(_), do: nil
end
