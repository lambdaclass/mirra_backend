defmodule DarkWorldsServer.RunnerSupervisor.Runner do
  use GenServer, restart: :transient
  require Logger
  alias DarkWorldsServer.Communication
  alias DarkWorldsServer.Communication.Proto.Move
  alias DarkWorldsServer.Communication.Proto.UseSkill

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

  def attack(runner_pid, user_id, action, timestamp) do
    GenServer.cast(runner_pid, {:attack, user_id, action, timestamp})
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
  def init(_) do
    priority =
      Application.fetch_env!(:dark_worlds_server, DarkWorldsServer.RunnerSupervisor.Runner)
      |> Keyword.fetch!(:process_priority)

    Process.flag(:priority, priority)

    {:ok, game_config_json} =
      Application.app_dir(:dark_worlds_server, "priv/config.json") |> File.read()

    game_config = GameBackend.parse_config(game_config_json)

    Process.send_after(self(), :game_timeout, @game_timeout_ms)
    Process.send_after(self(), :start_game_tick, @game_tick_start)

    state = %{
      game_state: GameBackend.new_game(game_config),
      game_tick: @game_tick_rate_ms,
      player_timestamps: %{},
      broadcast_topic: Communication.pubsub_game_topic(self()),
      user_to_player: %{},
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
    case GameBackend.add_player(state.game_state, character_name) do
      {:ok, {game_state, player_id}} ->
        state =
          Map.put(state, :game_state, game_state)
          |> put_in([:user_to_player, user_id], player_id)

        NewRelic.increment_custom_metric("GameBackend/TotalPlayers", 1)
        {:reply, {:ok, player_id}, state}

      {:error, :character_not_found} ->
        {:reply, {:error, "Character doesn't exists"}, state}
    end
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
        {:attack, user_id, %UseSkill{angle: angle, auto_aim: auto_aim, skill: skill}, timestamp},
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
    broadcast_game_start(state.broadcast_topic, Map.put(state.game_state, :player_timestamps, state.player_timestamps))

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

  def handle_info(msg, state) do
    Logger.error("Unexpected handle_info msg", %{msg: msg})
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, state) do
    NewRelic.increment_custom_metric("GameBackend/TotalPlayers", map_size(state.game_state.players))
    NewRelic.increment_custom_metric("GameBackend/TotalGames", -1)
  end

  ####################
  # Internal helpers #
  ####################
  defp broadcast_game_state(topic, game_state) do
    Phoenix.PubSub.broadcast(
      DarkWorldsServer.PubSub,
      topic,
      # {:game_state, transform_state_to_game_state(game_state)}
      {:game_state, game_state}
    )
  end

  defp broadcast_game_start(topic, game_state) do
    Phoenix.PubSub.broadcast(
      DarkWorldsServer.PubSub,
      topic,
      {:game_start, game_state}
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
    # game_winner = transform_player_to_game_player(winner)
    # game_state = transform_state_to_game_state(game_state)

    Phoenix.PubSub.broadcast(
      DarkWorldsServer.PubSub,
      topic,
      # {:game_ended, game_winner, game_state}
      {:game_ended, winner, game_state}
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
  defp action_skill_to_key("Skill1"), do: "2"
  defp action_skill_to_key(:skill_1), do: "2"
  defp action_skill_to_key(:skill_2), do: "3"
  defp action_skill_to_key(:skill_3), do: "4"
  defp action_skill_to_key(:skill_4), do: "5"
end
