defmodule DarkWorldsServer.RunnerSupervisor.BotPlayer do
  use GenServer, restart: :transient
  require Logger
  alias DarkWorldsServer.Communication
  alias DarkWorldsServer.Communication.Proto.Move
  alias DarkWorldsServer.Communication.Proto.UseSkill
  alias DarkWorldsServer.RunnerSupervisor.Runner

  # This variable will decide how much time passes between bot decisions in milis
  @decide_delay_ms 500

  # We'll decide the view range of a bot measured in grid cells
  # e.g. from {x=1, y=1} to {x=5, y=1} you have 4 cells
  @visibility_max_range_cells 2000

  # This number determines the amount of players needed in proximity for the bot to flee
  @amount_of_players_to_flee 3

  # The numbers of cell close to the bot in wich the enemies will count to flee
  @range_of_players_to_flee @visibility_max_range_cells + 500

  # The number of minimum playable radius where the bot could flee
  @min_playable_radius_flee 5000

  # Number to substract to the playable radio
  @radius_sub_to_escape 500

  # This is the amount of time between bots messages
  @game_tick_rate_ms 30

  #######
  # API #
  #######
  def start_link(game_pid, _args) do
    GenServer.start_link(__MODULE__, {game_pid, @game_tick_rate_ms})
  end

  def add_bot(bot_pid, bot_id) do
    GenServer.cast(bot_pid, {:add_bot, bot_id})
  end

  # def enable_bots(bot_pid) do
  #   GenServer.cast(bot_pid, {:bots_enabled, true})
  # end

  # def disable_bots(bot_pid) do
  #   GenServer.cast(bot_pid, {:bots_enabled, false})
  # end

  def toggle_bots(bot_pid, bots_active) do
    GenServer.cast(bot_pid, {:bots_enabled, bots_active})
  end

  #######################
  # GenServer callbacks #
  #######################
  @impl GenServer
  def init({game_pid, tick_rate}) do
    game_id = Communication.pid_to_external_id(game_pid)
    Phoenix.PubSub.subscribe(DarkWorldsServer.PubSub, "game_play_#{game_id}")

    {:ok,
     %{
       game_pid: game_pid,
       bots_enabled: true,
       game_tick_rate: tick_rate,
       players: [],
       bots: %{},
       game_state: %{}
     }}
  end

  @impl GenServer
  def handle_cast({:add_bot, bot_id}, state) do
    send(self(), {:decide_action, bot_id})
    send(self(), {:do_action, bot_id})

    {:noreply,
     put_in(state, [:bots, bot_id], %{
       alive: true,
       objective: :nothing,
       current_wandering_position: nil
     })}
  end

  def handle_cast({:bots_enabled, toggle}, state) do
    {:noreply, %{state | bots_enabled: toggle}}
  end

  @impl GenServer
  def handle_info({:decide_action, bot_id}, state) do
    bot_state = get_in(state, [:bots, bot_id])

    new_bot_state =
      case bot_state do
        %{action: :die} ->
          bot_state

        bot_state ->
          Process.send_after(self(), {:decide_action, bot_id}, @decide_delay_ms)

          bot = Enum.find(state.players, fn player -> player.id == bot_id end)

          closest_entities = get_closest_entities(state.game_state, bot)

          bot_state
          |> decide_objective(state, bot_id, closest_entities)
          |> decide_action(bot_id, state.players, state, closest_entities)
      end

    state = put_in(state, [:bots, bot_id], new_bot_state)

    {:noreply, state}
  end

  def handle_info({:do_action, bot_id}, state) do
    bot_state = get_in(state, [:bots, bot_id])

    if bot_state.alive do
      Process.send_after(self(), {:do_action, bot_id}, state.game_tick_rate)
      do_action(bot_id, state.game_pid, state.players, bot_state)
    end

    {:noreply, state}
  end

  def handle_info({:game_state, game_state}, state) do
    players =
      game_state.players
      |> Enum.map(&Map.take(&1, [:id, :health, :position]))
      |> Enum.sort_by(& &1.health, :desc)

    bots =
      Enum.reduce(players, state.bots, fn player, acc_bots ->
        case {player.health <= 0, acc_bots[player.id]} do
          {true, bot} when not is_nil(bot) -> put_in(acc_bots, [player.id, :alive], false)
          _ -> acc_bots
        end
      end)

    {:noreply, %{state | players: players, bots: bots, game_state: game_state}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  #############################
  # Callbacks implementations #
  #############################
  defp decide_action(%{alive: false} = bot_state, _, _, _game_state, _closest_entities) do
    Map.put(bot_state, :action, :die)
  end

  defp decide_action(
         %{objective: :wander} = bot_state,
         bot_id,
         players,
         _game_state,
         _closest_entities
       ) do
    bot = Enum.find(players, fn player -> player.id == bot_id end)

    set_correct_wander_state(bot, bot_state)
  end

  defp decide_action(
         %{objective: :chase_loot} = bot_state,
         _bot_id,
         _players,
         %{game_state: game_state},
         %{loots_by_distance: loots_by_distance}
       ) do
    closest_loot = List.first(loots_by_distance)

    angle = closest_loot.angle_direction_to_entity

    center = game_state.shrinking_center
    radius = game_state.playable_radius

    if position_out_of_radius?(closest_loot.entity_position, center, radius) do
      flee_angle_direction = if angle <= 0, do: angle + 180, else: angle - 180
      Map.put(bot_state, :action, {:move, flee_angle_direction})
    else
      Map.put(bot_state, :action, {:move, angle})
    end
  end

  defp decide_action(
         %{objective: :chase_enemy} = bot_state,
         bot_id,
         _players,
         %{game_state: game_state},
         %{enemies_by_distance: enemies_by_distance}
       ) do
    bot = Enum.find(game_state.players, fn player -> player.id == bot_id end)

    closest_enemy = List.first(enemies_by_distance)

    amount_of_players_in_flee_proximity =
      enemies_by_distance
      |> Enum.count(fn p -> p.distance_to_entity < @range_of_players_to_flee end)

    danger_zone =
      amount_of_players_in_flee_proximity >= @amount_of_players_to_flee or
        (bot.health <= 25 and amount_of_players_in_flee_proximity >= 1)

    playable_radius_closed = game_state.playable_radius <= @min_playable_radius_flee

    cond do
      danger_zone and not playable_radius_closed ->
        %{angle_direction_to_entity: angle} = hd(enemies_by_distance)
        flee_angle_direction = if angle <= 0, do: angle + 180, else: angle - 180
        Map.put(bot_state, :action, {:move, flee_angle_direction})

      skill_would_hit?(bot, closest_enemy) ->
        Map.put(bot_state, :action, {:attack, closest_enemy, "BasicAttack"})

      true ->
        Map.put(bot_state, :action, {:move, closest_enemy.angle_direction_to_entity})
    end
  end

  defp decide_action(
         %{objective: :flee_from_zone} = bot_state,
         bot_id,
         players,
         state,
         _closest_entities
       ) do
    bot = Enum.find(players, fn player -> player.id == bot_id end)

    target =
      calculate_circle_point(
        bot.position,
        state.game_state.shrinking_center,
        false
      )

    Map.put(bot_state, :action, {:move, target})
  end

  defp decide_action(bot_state, _bot_id, _players, _game_state, _closest_entities) do
    bot_state
    |> Map.put(:action, {:nothing, nil})
  end

  defp do_action(bot_id, game_pid, _players, %{action: {:move, angle}}) do
    Runner.move(game_pid, bot_id, %Move{angle: angle}, nil)
  end

  defp do_action(bot_id, game_pid, _players, %{
         action: {:attack, %{type: :enemy, attacking_angle_direction: angle}, skill}
       }) do
    Runner.basic_attack(game_pid, bot_id, %UseSkill{angle: angle, skill: skill}, nil)
  end

  defp do_action(_bot_id, _game_pid, _players, _) do
    nil
  end

  ####################
  # Internal helpers #
  ####################
  def calculate_circle_point(%{x: start_x, y: start_y}, %{x: end_x, y: end_y}, use_inaccuracy) do
    calculate_circle_point(start_x, start_y, end_x, end_y, use_inaccuracy)
  end

  def calculate_circle_point(cx, cy, x, y, use_inaccuracy) do
    Nx.atan2(x - cx, y - cy)
    |> maybe_add_inaccuracy_to_angle(use_inaccuracy)
    |> Nx.multiply(Nx.divide(180.0, Nx.Constants.pi()))
    |> Nx.to_number()
    |> Kernel.*(-1)
  end

  defp maybe_add_inaccuracy_to_angle(angle, false), do: angle

  defp maybe_add_inaccuracy_to_angle(angle, true) do
    Nx.add(angle, Enum.random([-0.1, -0.01, 0, 0.01, 0.1]))
  end

  def decide_objective(bot_state, %{bots_enabled: false}, _bot_id, _closest_entities) do
    Map.put(bot_state, :objective, :nothing)
  end

  def decide_objective(bot_state, %{game_state: game_state}, bot_id, %{
        enemies_by_distance: enemies_by_distance,
        loots_by_distance: loots_by_distance
      }) do
    bot = Enum.find(game_state.players, fn player -> player.id == bot_id end)

    closests_entities = [List.first(enemies_by_distance), List.first(loots_by_distance)]

    closest_entity = Enum.min_by(closests_entities, fn e -> if e, do: e.distance_to_entity end)

    center = game_state.shrinking_center
    radius = game_state.playable_radius

    out_of_area? = position_out_of_radius?(bot.position, center, radius)

    if out_of_area? do
      Map.put(bot_state, :objective, :flee_from_zone)
    else
      set_objective(bot_state, bot, game_state, closest_entity)
    end
  end

  def decide_objective(bot_state, _, _, _), do: Map.put(bot_state, :objective, :nothing)

  defp set_objective(bot_state, nil, _game_state, _closest_entities),
    do: Map.put(bot_state, :objective, :waiting_game_update)

  defp set_objective(bot_state, bot, game_state, nil) do
    maybe_put_wandering_position(bot_state, bot, game_state)
  end

  defp set_objective(bot_state, _bot, _game_state, closest_entity) do
    cond do
      closest_entity.type == :enemy ->
        Map.put(bot_state, :objective, :chase_enemy)

      closest_entity.type == :loot ->
        Map.put(bot_state, :objective, :chase_loot)
    end
  end

  defp get_closest_entities(_, nil), do: %{}

  defp get_closest_entities(game_state, bot) do
    # TODO maybe we could add a priority to the entities.
    # e.g. if the bot has low health priorities the loot boxes
    enemies_by_distance =
      game_state.players
      |> Enum.filter(fn player -> player.status == :alive and player.id != bot.id end)
      |> map_entities(bot, :enemy)

    loots_by_distance =
      game_state.loots
      |> map_entities(bot, :loot)

    %{
      enemies_by_distance: enemies_by_distance,
      loots_by_distance: loots_by_distance
    }
  end

  defp get_distance_to_point(%{x: start_x, y: start_y}, %{x: end_x, y: end_y}) do
    diagonal_movement_cost = 14
    straight_movement_cost = 10

    x_distance = abs(end_x - start_x)
    y_distance = abs(end_y - start_y)
    remaining = abs(x_distance - y_distance)

    (diagonal_movement_cost * Enum.min([x_distance, y_distance]) +
       remaining * straight_movement_cost) / 10.0
  end

  defp map_entities(entities, bot, type) do
    entities
    |> Enum.map(fn entity ->
      %{
        type: type,
        entity_id: entity.id,
        distance_to_entity: get_distance_to_point(bot.position, entity.position),
        angle_direction_to_entity: calculate_circle_point(bot.position, entity.position, false),
        attacking_angle_direction: calculate_circle_point(bot.position, entity.position, true),
        entity_position: entity.position
      }
    end)
    |> Enum.sort_by(fn distances -> distances.distance_to_entity end, :asc)
    |> Enum.filter(fn distances -> distances.distance_to_entity <= @visibility_max_range_cells end)
  end

  defp skill_would_hit?(bot, %{distance_to_entity: distance_to_entity}) do
    # TODO: We should find a way to use the skill of the character distance
    case bot.character_name do
      "H4ck" -> distance_to_entity < 1000 and Enum.random(0..100) < 40
      "Muflus" -> distance_to_entity < 450 and Enum.random(0..100) < 30
    end
  end

  def maybe_put_wandering_position(
        %{objective: :wander, current_wandering_position: current_wandering_position} = bot_state,
        bot,
        game_state
      ) do
    if get_distance_to_point(bot.position, %{
         x: current_wandering_position.x,
         y: current_wandering_position.y
       }) <
         500 do
      put_wandering_position(bot_state, bot, game_state)
    else
      bot_state
    end
  end

  def maybe_put_wandering_position(bot_state, bot, game_state),
    do: put_wandering_position(bot_state, bot, game_state)

  def put_wandering_position(
        bot_state,
        %{position: bot_position},
        game_state
      ) do
    bot_visibility_radius = @visibility_max_range_cells * 2

    # We need to pick and X and Y wich are in a safe zone close to the bot that's also inside of the board
    left_x =
      Enum.max([
        game_state.shrinking_center.x - game_state.playable_radius,
        bot_position.x - bot_visibility_radius,
        0
      ])

    right_x =
      Enum.min([
        game_state.shrinking_center.x + game_state.playable_radius,
        bot_position.x + bot_visibility_radius,
        game_state.board.width
      ])

    down_y =
      Enum.max([
        game_state.shrinking_center.y - game_state.playable_radius,
        bot_position.y - bot_visibility_radius,
        0
      ])

    up_y =
      Enum.min([
        game_state.shrinking_center.y + game_state.playable_radius,
        bot_position.y + bot_visibility_radius,
        game_state.board.height
      ])

    wandering_position = %{
      x: :rand.uniform() * (right_x - left_x) + left_x,
      y: :rand.uniform() * (up_y - down_y) + down_y
    }

    Map.merge(bot_state, %{current_wandering_position: wandering_position, objective: :wander})
  end

  defp set_correct_wander_state(nil, bot_state), do: Map.put(bot_state, :action, {:nothing, nil})

  defp set_correct_wander_state(
         bot,
         %{current_wandering_position: wandering_position} = bot_state
       ) do
    target =
      calculate_circle_point(
        bot.position,
        wandering_position,
        false
      )

    Map.put(bot_state, :action, {:move, target})
  end

  defp position_out_of_radius?(position, center, playable_radius) do
    distance =
      (:math.pow(position.x - center.x, 2) + :math.pow(position.y - center.y, 2))
      |> :math.sqrt()

    # We'll substract a fixed value to the playable radio to have some space between the bot
    # and the unplayable zone to avoid being on the edge of both
    distance > playable_radius - @radius_sub_to_escape
  end
end
