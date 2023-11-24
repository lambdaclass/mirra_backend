defmodule DarkWorldsServer.RunnerSupervisor.Runner do
  use GenServer, restart: :transient
  require Logger
  alias DarkWorldsServer.Communication
  alias DarkWorldsServer.Communication.Proto.Move
  alias DarkWorldsServer.Communication.Proto.UseSkill
  alias DarkWorldsServer.RunnerSupervisor.BotPlayer

  # This is the amount of time between state updates in milliseconds
  @game_tick_rate_ms 20
  # Amount of time between loot spawn
  @loot_spawn_rate_ms 20_000
  # Amount of time between loot spawn
  @game_tick_start 5_000
  ## Time between checking that a game has ended
  @check_game_ended_interval_ms 1_000
  ## Time to wait between a game ended detected and shutting down this process
  @game_ended_shutdown_wait_ms 10_000
  ## Timeout to stop game process, this is a safeguard in case the process
  ## does not detect a game ending and stays as a zombie
  @game_timeout_ms 600_000

  #######
  # API #
  #######
  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def get_config(runner_pid) do
    GenServer.call(runner_pid, :get_config)
  end

  def join(runner_pid, user_id, character_name) do
    GenServer.call(runner_pid, {:join, user_id, character_name})
  end

  def move(runner_pid, user_id, action, timestamp) do
    GenServer.cast(runner_pid, {:move, user_id, action, timestamp})
  end

  def basic_attack(runner_pid, user_id, action, timestamp) do
    GenServer.cast(runner_pid, {:basic_attack, user_id, action, timestamp})
  end

  def skill(runner_pid, user_id, action) do
    GenServer.cast(runner_pid, {:skill, user_id, action})
  end

  def start_game_tick(runner_pid) do
    GenServer.cast(runner_pid, :start_game_tick)
  end

  if Mix.env() == :dev do
    def bot_join(pid_middle_number) do
      join(:c.pid(0, pid_middle_number, 0), "bot", "h4ck")
    end
  end

  #######################
  # GenServer callbacks #
  #######################
  @impl true
  def init(%{bot_count: bot_count}) do
    priority =
      Application.fetch_env!(:dark_worlds_server, DarkWorldsServer.RunnerSupervisor.Runner)
      |> Keyword.fetch!(:process_priority)

    Process.flag(:priority, priority)

    {:ok, game_config_json} =
      Application.app_dir(:dark_worlds_server, "priv/config.json") |> File.read()

    game_config = GameBackend.parse_config(game_config_json)

    Process.send_after(self(), :game_timeout, @game_timeout_ms)
    Process.send_after(self(), :start_game_tick, @game_tick_start)

    send(self(), {:spawn_bots, bot_count})

    state = %{
      game_state: GameBackend.new_game(game_config),
      game_tick: @game_tick_rate_ms,
      player_timestamps: %{},
      broadcast_topic: Communication.pubsub_game_topic(self()),
      user_to_player: %{},
      bot_count: bot_count,
      bot_handler_pid: nil,
      last_standing_players: []
    }

    Process.put(:map_size, {game_config.game.width, game_config.game.height})

    NewRelic.increment_custom_metric("GameBackend/TotalGames", 1)
    {:ok, state}
  end

  @impl true
  def handle_call(:get_config, _from, state) do
    {:reply, {:ok, state.game_state.config}, state}
  end

  @impl true
  def handle_call({:join, user_id, character_name}, _from, state) do
    {game_state, player_id} = GameBackend.add_player(state.game_state, character_name)

    state =
      Map.put(state, :game_state, game_state)
      |> put_in([:user_to_player, user_id], player_id)

    NewRelic.increment_custom_metric("GameBackend/TotalPlayers", 1)
    {:reply, {:ok, player_id}, state}
  end

  @impl true
  def handle_call(msg, from, state) do
    Logger.error("Unexpected handle_call msg", %{msg: msg, from: from})
    {:noreply, state}
  end

  @impl true
  def handle_cast({:move, user_id, %Move{angle: angle}, timestamp}, state) do
    player_id = state.user_to_player[user_id] || user_id
    game_state = GameBackend.move_player(state.game_state, player_id, angle)

    state =
      Map.put(state, :game_state, game_state)
      |> put_in([:player_timestamps, user_id], timestamp)

    {:noreply, state}
  end

  @impl true
  def handle_cast(
        {:basic_attack, user_id, %UseSkill{angle: angle, auto_aim: auto_aim, skill: skill}, timestamp},
        state
      ) do
    player_id = state.user_to_player[user_id] || user_id
    skill_key = action_skill_to_key(skill)

    game_state =
      GameBackend.activate_skill(state.game_state, player_id, skill_key, %{
        "direction_angle" => Float.to_string(angle),
        "auto_aim" => to_string(auto_aim)
      })

    state =
      Map.put(state, :game_state, game_state)
      |> put_in([:player_timestamps, user_id], timestamp)

    {:noreply, state}
  end

  def handle_cast(msg, state) do
    Logger.error("Unexpected handle_cast msg", %{msg: msg})
    {:noreply, state}
  end

  @impl true
  def handle_info(:start_game_tick, state) do
    Process.send_after(self(), :game_tick, @game_tick_rate_ms)
    Process.send_after(self(), :spawn_loot, @loot_spawn_rate_ms)
    Process.send_after(self(), :check_game_ended, @check_game_ended_interval_ms * 10)

    state = Map.put(state, :last_game_tick_at, System.monotonic_time(:millisecond))
    {:noreply, state}
  end

  def handle_info(:game_tick, state) do
    Process.send_after(self(), :game_tick, @game_tick_rate_ms)

    now = System.monotonic_time(:millisecond)
    time_diff = now - state.last_game_tick_at
    game_state = GameBackend.game_tick(state.game_state, time_diff)
    now_after_tick = System.monotonic_time(:millisecond)
    NewRelic.report_custom_metric("GameBackend/GameTickExecutionTimeMs", now_after_tick - now)

    broadcast_game_state(
      state.broadcast_topic,
      Map.put(game_state, :player_timestamps, state.player_timestamps)
    )

    {:noreply,
     %{
       state
       | game_state: game_state,
         last_game_tick_at: now,
         last_standing_players: update_last_standing_players(state)
     }}
  end

  def handle_info(:spawn_loot, state) do
    Process.send_after(self(), :spawn_loot, @loot_spawn_rate_ms)

    {game_state, _loot_id} = GameBackend.spawn_random_loot(state.game_state)

    {:noreply, %{state | game_state: game_state}}
  end

  def handle_info(:check_game_ended, state) do
    Process.send_after(self(), :check_game_ended, @check_game_ended_interval_ms)

    case check_game_ended(Map.values(state.game_state.players), state.last_standing_players) do
      :ongoing ->
        :skip

      {:ended, winner} ->
        broadcast_game_ended(
          state.broadcast_topic,
          winner,
          Map.put(state.game_state, :player_timestamps, state.player_timestamps)
        )

        ## The idea of having this waiting period is in case websocket processes keep
        ## sending messages, this way we give some time before making them crash
        ## (sending to inexistant process will cause them to crash)
        Process.send_after(self(), :game_ended, @game_ended_shutdown_wait_ms)
    end

    {:noreply, state}
  end

  def handle_info(:game_ended, state) do
    {:stop, :normal, state}
  end

  def handle_info(:game_timeout, state) do
    {:stop, {:shutdown, :game_timeout}, state}
  end

  def handle_info({:spawn_bots, bot_count}, state) when bot_count > 0 do
    {:ok, bot_handler_pid} = BotPlayer.start_link(self(), %{})

    {game_state, bots_ids} =
      Enum.reduce(0..(bot_count - 1), {state.game_state, []}, fn _, {acc_game_state, bots} ->
        character = Enum.random(["h4ck", "muflus"])
        {new_game_state, player_id} = GameBackend.add_player(acc_game_state, character)

        {new_game_state, [player_id | bots]}
      end)

    Process.send_after(self(), {:activate_bots, bots_ids}, 10_000)

    state =
      Map.put(state, :game_state, game_state)
      |> Map.put(:bot_handler_pid, bot_handler_pid)

    NewRelic.increment_custom_metric("GameBackend/TotalBots", bot_count)
    {:noreply, state}
  end

  def handle_info({:activate_bots, bots_ids}, state) do
    Enum.each(bots_ids, fn player_id -> BotPlayer.add_bot(state.bot_handler_pid, player_id) end)
    {:noreply, state}
  end

  def handle_info({:spawn_bots, _bot_count}, state) do
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.error("Unexpected handle_info msg", %{msg: msg})
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, state) do
    player_count = length(state.game_state.players) - state.bot_count
    NewRelic.increment_custom_metric("GameBackend/TotalPlayers", -player_count)
    NewRelic.increment_custom_metric("GameBackend/TotalBots", -bot_count)
    NewRelic.increment_custom_metric("GameBackend/TotalGames", -1)
  end

  ####################
  # Internal helpers #
  ####################
  defp broadcast_game_state(topic, game_state) do
    Phoenix.PubSub.broadcast(
      DarkWorldsServer.PubSub,
      topic,
      {:game_state, transform_state_to_game_state(game_state)}
    )
  end

  defp update_last_standing_players(%{last_standing_players: last_standing_players} = state) do
    players_alive = Enum.filter(Map.values(state.game_state.players), fn player -> player.status == :alive end)

    case players_alive do
      [] -> last_standing_players
      players_alive -> players_alive
    end
  end

  defp broadcast_game_ended(topic, winner, game_state) do
    game_winner = transform_player_to_game_player(winner)
    game_state = transform_state_to_game_state(game_state)

    Phoenix.PubSub.broadcast(
      DarkWorldsServer.PubSub,
      topic,
      {:game_ended, game_winner, game_state}
    )
  end

  defp check_game_ended(players, last_standing_players) do
    players_alive = Enum.filter(players, fn player -> player.status == :alive end)

    case players_alive do
      ^players ->
        :ongoing

      [_, _ | _] ->
        :ongoing

      [player] ->
        {:ended, player}

      [] ->
        # TODO we should use a tiebreaker instead of picking the 1st one in the list
        {:ended, hd(last_standing_players)}
    end
  end

  defp action_skill_to_key("BasicAttack"), do: "1"
  defp action_skill_to_key(:skill_1), do: "2"
  defp action_skill_to_key(:skill_2), do: "3"
  defp action_skill_to_key(:skill_3), do: "4"
  defp action_skill_to_key(:skill_4), do: "5"

  defp transform_state_to_game_state(game_state) do
    %{
      __struct__: GameBackend.Game,
      players: transform_players_to_game_players(game_state.players),
      board: %{
        width: game_state.config.game.width,
        __struct__: GameBackend.Board,
        height: game_state.config.game.height
      },
      projectiles: transform_projectiles_to_game_projectiles(game_state.projectiles),
      killfeed: transform_killfeed_to_game_killfeed(game_state.killfeed),
      playable_radius: game_state.zone.radius,
      shrinking_center: transform_position_to_game_position(game_state.zone.center),
      loots: transform_loots_to_game_loots(game_state.loots),
      next_killfeed: [],
      next_projectile_id: 0,
      next_loot_id: 0,
      player_timestamps: game_state.player_timestamps
    }
  end

  defp transform_players_to_game_players(players) do
    Enum.map(players, fn {_id, player} -> transform_player_to_game_player(player) end)
  end

  defp transform_player_to_game_player(player) do
    %{
      ## Transformed
      __struct__: GameBackend.Player,
      id: player.id,
      position: transform_position_to_game_position(player.position),
      status: if(player.health <= 0, do: :dead, else: :alive),
      health: player.health,
      body_size: player.size,
      character_name: transform_character_name_to_game_character_name(player.character.name),
      ## Placeholder values
      kill_count: 0,
      effects: %{},
      death_count: 0,
      action: transform_action_to_game_action(player.actions),
      direction: transform_angle_to_game_relative_position(player.direction),
      aoe_position: %GameBackend.Position{x: 0, y: 0}
    }
    |> transform_player_cooldowns_to_game_player_cooldowns(player)
  end

  defp transform_player_cooldowns_to_game_player_cooldowns(game_player, player) do
    game_cooldowns = %{
      basic_skill_cooldown_left: transform_milliseconds_to_game_millis_time(player.cooldowns["1"]),
      skill_1_cooldown_left: transform_milliseconds_to_game_millis_time(player.cooldowns["2"]),
      skill_2_cooldown_left: transform_milliseconds_to_game_millis_time(player.cooldowns["3"]),
      skill_3_cooldown_left: transform_milliseconds_to_game_millis_time(player.cooldowns["4"]),
      skill_4_cooldown_left: transform_milliseconds_to_game_millis_time(player.cooldowns["5"])
    }

    Map.merge(game_player, game_cooldowns)
  end

  defp transform_projectiles_to_game_projectiles(projectiles) do
    Enum.map(projectiles, fn projectile ->
      %GameBackend.Projectile{
        id: projectile.id,
        position: transform_position_to_game_position(projectile.position),
        direction: transform_angle_to_game_relative_position(projectile.direction_angle),
        speed: projectile.speed,
        range: projectile.max_distance,
        player_id: projectile.player_id,
        damage: projectile.damage,
        status: :active,
        projectile_type: :bullet,
        pierce: false,
        # For some reason they are initiated like this
        last_attacked_player_id: projectile.player_id,
        # Honestly don't see why client should care about this
        remaining_ticks: 9999,
        skill_name: transform_projectile_name_to_game_projectile_skill_name(projectile.name)
      }
    end)
  end

  defp transform_projectile_name_to_game_projectile_skill_name("projectile_slingshot"),
    do: "SLINGSHOT"

  defp transform_projectile_name_to_game_projectile_skill_name("projectile_multishot"),
    do: "MULTISHOT"

  defp transform_projectile_name_to_game_projectile_skill_name("projectile_disarm"), do: "DISARM"
  # TEST skills
  defp transform_projectile_name_to_game_projectile_skill_name("projectile_poison_dart"),
    do: "DISARM"

  defp transform_milliseconds_to_game_millis_time(nil), do: %{high: 0, low: 0}
  defp transform_milliseconds_to_game_millis_time(cooldown), do: %{high: 0, low: cooldown}

  defp transform_loots_to_game_loots(loots) do
    Enum.map(loots, fn loot ->
      %{
        id: loot.id,
        loot_type: {:health, :placeholder},
        position: transform_position_to_game_position(loot.position)
      }
    end)
  end

  defp transform_position_to_game_position(position) do
    {width, height} = Process.get(:map_size)

    %GameBackend.Position{
      x: -1 * position.y + div(width, 2),
      y: position.x + div(height, 2)
    }
  end

  defp transform_character_name_to_game_character_name("h4ck"), do: "H4ck"
  defp transform_character_name_to_game_character_name("muflus"), do: "Muflus"

  defp transform_angle_to_game_relative_position(angle) do
    angle_radians = Nx.divide(Nx.Constants.pi(), 180) |> Nx.multiply(angle)
    x = Nx.cos(angle_radians) |> Nx.to_number()
    y = Nx.sin(angle_radians) |> Nx.to_number()
    %GameBackend.RelativePosition{x: x, y: y}
  end

  defp transform_action_to_game_action([]), do: :nothing
  defp transform_action_to_game_action([:nothing | _]), do: :nothing
  defp transform_action_to_game_action([:moving | _]), do: :moving
  defp transform_action_to_game_action([{:using_skill, "1"} | _]), do: :attacking
  defp transform_action_to_game_action([{:using_skill, "2"} | _]), do: :executingskill2

  defp transform_killfeed_to_game_killfeed([]), do: []

  defp transform_killfeed_to_game_killfeed([
         {{:player, killer_id}, killed_id} | tail
       ]),
       do: [%{killed_by: killer_id, killed: killed_id} | transform_killfeed_to_game_killfeed(tail)]

  defp transform_killfeed_to_game_killfeed([
         {:zone, killed_id} | tail
       ]),
       do: [%{killed_by: 9999, killed: killed_id} | transform_killfeed_to_game_killfeed(tail)]

  defp transform_killfeed_to_game_killfeed([
         {:loot, killed_id} | tail
       ]),
       do: [%{killed_by: 1111, killed: killed_id} | transform_killfeed_to_game_killfeed(tail)]
end
