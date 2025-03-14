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

    Process.send_after(self(), :allow_map_build, Enum.random(1000..2000))
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

        # # only load collision grid once
        if state.can_build_map && is_nil(new_state.bot_state_machine.collision_grid) and not is_nil(new_state.game_state) and not is_nil(new_state.game_state.obstacles) and not Enum.empty?(new_state.game_state.obstacles) do
          obstacles = new_state.game_state.obstacles
            |> Enum.map(fn {obstacle_id, obstacle} -> {obstacle_id, Map.take(Map.from_struct(obstacle), [:id, :shape, :position, :radius, :vertices, :speed, :category, :direction, :is_moving, :name])} end)
            |> Enum.map(fn {obstacle_id, obstacle} -> {obstacle_id, Map.put(obstacle, :position, %{x: obstacle.position.x, y: obstacle.position.y})} end)
            |> Enum.map(fn {obstacle_id, obstacle} -> {obstacle_id, Map.put(obstacle, :vertices, Enum.map(obstacle.vertices.positions, fn position -> %{x: position.x, y: position.y} end))} end)
            |> Enum.map(fn {obstacle_id, obstacle} -> {obstacle_id, Map.put(obstacle, :direction, %{x: obstacle.direction.x, y: obstacle.direction.y})} end)
            |> Enum.map(fn {obstacle_id, obstacle} -> {obstacle_id, Map.put(obstacle, :shape, get_shape(obstacle.shape))} end)
            |> Enum.map(fn {obstacle_id, obstacle} -> {obstacle_id, Map.put(obstacle, :category, get_category(obstacle.category))} end)
            |> Map.new()

          # IO.inspect(obstacles, label: "OBSTACLES")

          update = %{
            bot_state_machine: Map.put(bot_state_machine, :collision_grid, AStarNative.build_collision_grid(obstacles)),
          }

          new_state = Map.merge(new_state, update)
          {:ok, new_state}
        else
          {:ok, new_state}
        end

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
    Logger.error("Stack trace: #{inspect(Process.info(self(), :current_stacktrace) )}")
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
