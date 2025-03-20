defmodule BotManager.GameSocketHandler do
  @moduledoc """
  BotManager socket handler.
  It handles the communication with the server.
  """

  alias BotManager.BotStateMachine
  alias BotManager.BotStateMachineChecker

  use WebSockex, restart: :temporary
  require Logger

  defp min_decision_delay_ms() do
    if System.get_env("PATHFINDING_TEST") == "true" do
      100
    else
      750
    end
  end

  defp max_decision_delay_ms() do
    if System.get_env("PATHFINDING_TEST") == "true" do
      150
    else
      1250
    end
  end

  @delay_before_map_grid_building_ms 1000

  @action_delay_ms 30

  def start_link(%{"bot_client" => bot_client, "game_id" => game_id} = params) do
    ws_url = ws_url(params)

    WebSockex.start_link(ws_url, __MODULE__, %{
      client_id: bot_client,
      game_id: game_id
    })
  end

  #######################
  #      handlers       #
  #######################

  def handle_connect(_conn, state) do
    send(self(), :decide_action)
    send(self(), :perform_action)

    state =
      state
      |> Map.put(:bots_enabled?, true)
      |> Map.put(:attack_blocked, false)
      |> Map.put(:bot_state_machine, BotStateMachineChecker.new())
      |> Map.put(:can_build_map, false)

    # This delay ensures we give some time to the board liveview to join on time before the game starts.
    # Ideally we should make the collision grid building NIF faster instead of doing this so that we don't have problems
    # running everything on the same machine (for example when testing locally)
    Process.send_after(self(), :allow_map_build, @delay_before_map_grid_building_ms)
    {:ok, state}
  end

  def handle_frame({:binary, frame}, state) do
    case BotManager.Protobuf.GameEvent.decode(frame) do
      %{event: {:update, game_state}} ->
        bot_player = Map.get(game_state.players, state.player_id)

        state =
          if Map.has_key?(state, :bot_skills) do
            state
          else
            {:player, aditional_info} = bot_player.aditional_info

            skills =
              BotManager.Utils.list_character_skills_from_config(aditional_info.character_name, state.config.characters)

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

        new_state = Map.merge(state, update)

        {:ok, maybe_build_map(new_state)}

      %{event: {:joined, joined}} ->
        {:ok, Map.merge(state, joined)}

      %{event: {:finished, _}} ->
        exit(:shutdown)

      %{event: {:toggle_bots, _}} ->
        {:ok, Map.put(state, :bots_enabled?, not state.bots_enabled?)}

      _ ->
        {:ok, state}
    end
  end

  def handle_info(:allow_map_build, state) do
    state = Map.put(state, :can_build_map, true)

    {:ok, state}
  end

  def handle_info(:decide_action, state) do
    Process.send_after(self(), :decide_action, Enum.random(min_decision_delay_ms()..max_decision_delay_ms()))

    %{action: action, bot_state_machine: bot_state_machine} = BotStateMachine.decide_action(state)

    state =
      state
      |> Map.put(:current_action, %{action: action, sent: false})
      |> Map.put(:bot_state_machine, bot_state_machine)

    {:ok, state}
  end

  def handle_info(:unblock_attack, state) do
    {:ok, Map.put(state, :attack_blocked, false)}
  end

  def handle_info(:perform_action, state) do
    Process.send_after(self(), :perform_action, @action_delay_ms)
    send_current_action(state)
    {:ok, update_block_attack_state(state)}
  end

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
          |> Map.from_struct()
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

  defp update_block_attack_state(%{current_action: %{action: {:use_skill, _, _}, sent: false}} = state) do
    Process.send_after(self(), :unblock_attack, 100)

    Map.put(state, :attack_blocked, true)
    |> Map.put(:current_action, Map.put(state.current_action, :sent, true))
  end

  defp update_block_attack_state(state), do: state

  def handle_cast({:send, {_type, _msg} = frame}, state) do
    {:reply, frame, state}
  end

  defp send_current_action(%{current_action: %{action: {:move, direction}, sent: false}}) do
    timestamp = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

    game_action =
      BotManager.Protobuf.GameAction.encode(%BotManager.Protobuf.GameAction{
        action_type:
          {:move,
           %BotManager.Protobuf.Move{
             direction: %BotManager.Protobuf.Direction{
               x: direction.x,
               y: direction.y
             }
           }},
        timestamp: timestamp
      })

    WebSockex.cast(self(), {:send, {:binary, game_action}})
  end

  defp send_current_action(%{current_action: %{action: {:use_skill, skill_key, direction}, sent: false}}) do
    timestamp = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

    game_action =
      BotManager.Protobuf.GameAction.encode(%BotManager.Protobuf.GameAction{
        action_type:
          {:attack,
           %BotManager.Protobuf.Attack{
             skill: skill_key,
             parameters: %BotManager.Protobuf.AttackParameters{
               target: %BotManager.Protobuf.Direction{
                 x: direction.x,
                 y: direction.y
               }
             }
           }},
        timestamp: timestamp
      })

    WebSockex.cast(self(), {:send, {:binary, game_action}})
  end

  defp send_current_action(_), do: nil

  defp ws_url(%{
         "bot_client" => bot_client,
         "game_id" => game_id,
         "arena_host" => arena_host
       }) do
    Logger.info("Connecting bot with client: #{bot_client} to game: #{game_id} in the server: #{arena_host}")

    if arena_host == "localhost" do
      "ws://localhost:4000/play/#{game_id}/#{bot_client}"
    else
      "wss://#{arena_host}/play/#{game_id}/#{bot_client}"
    end
  end

  def terminate(close_reason, state) do
    Logger.error("Terminating bot with reason: #{inspect(close_reason)}")
    Logger.error("Terminating bot in state machine step: #{inspect(state.bot_state_machine)}")
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
