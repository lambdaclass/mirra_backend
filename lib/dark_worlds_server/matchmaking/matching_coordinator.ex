defmodule DarkWorldsServer.Matchmaking.MatchingCoordinator do
  alias DarkWorldsServer.Communication
  alias DarkWorldsServer.RunnerSupervisor
  use GenServer

  ## Amount of players needed to start a game
  @session_player_amount 10
  ## Time to wait for a matching session to be full
  @start_game_timeout_ms 9_500

  #######
  # API #
  #######
  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def join(user_id) do
    GenServer.call(__MODULE__, {:join, user_id})
  end

  def leave(user_id) do
    GenServer.call(__MODULE__, {:leave, user_id})
  end

  #######################
  # GenServer callbacks #
  #######################
  @impl true
  def init(_args) do
    send(self(), :simulate_player_joined)
    {:ok, %{players: [], session: :unset, curent_lobby_players: 0}}
  end

  @impl true
  def handle_call({:join, user_id}, {from, _}, %{players: []} = state) do
    session_ref = make_ref()
    Process.send_after(self(), {:check_timeout, session_ref}, @start_game_timeout_ms)
    players = [{user_id, from}]
    new_state = %{state | players: players, session: session_ref, curent_lobby_players: 1}
    notify_players_amount(new_state, @session_player_amount)

    {:reply, :ok, new_state}
  end

  def handle_call({:join, user_id}, {from, _}, %{players: players} = state) do
    if Enum.any?(players, fn {player_user_id, _} -> player_user_id == user_id end) do
      {:reply, :ok, state}
    else
      players = [{user_id, from} | state.players]
      send(self(), :check_capacity)
      new_state = %{state | players: players, curent_lobby_players: state.curent_lobby_players + 1}
      notify_players_amount(new_state, @session_player_amount)
      {:reply, :ok, new_state}
    end
  end

  def handle_call({:leave, user_id}, _from, state) do
    players = Enum.filter(state.players, fn {player_user_id, _} -> player_user_id != user_id end)
    new_state = %{state | players: players, curent_lobby_players: state.curent_lobby_players - 1}

    notify_players_amount(new_state, @session_player_amount)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_info({:check_timeout, session_ref}, %{session: session_ref, players: [_ | _]} = state) do
    bot_count = @session_player_amount - length(state.players)
    {:ok, game_pid, game_config} = start_game()
    players = consume_and_notify_players(state.players, state, game_pid, game_config, @session_player_amount)
    trigger_bots(bot_count, game_pid)
    new_session_ref = make_ref()
    Process.send_after(self(), {:check_timeout, new_session_ref}, @start_game_timeout_ms)
    {:noreply, %{state | players: players, session: new_session_ref, curent_lobby_players: 0}}
  end

  def handle_info({:check_timeout, _session_ref}, %{session: _other_session_ref} = state) do
    {:noreply, state}
  end

  def handle_info(:simulate_player_joined, %{players: []} = state) do
    Process.send_after(self(), :simulate_player_joined, 1000)
    {:noreply, state}
  end

  def handle_info(:simulate_player_joined, %{curent_lobby_players: curent_lobby_players, players: players} = state) do
    Process.send_after(self(), :simulate_player_joined, 1000)
    current_player = length(players)
    limit = @session_player_amount - (current_player + curent_lobby_players)

    new_state =
      %{state | curent_lobby_players: curent_lobby_players + Enum.random(0..Enum.min([2, limit]))}

    notify_players_amount(new_state, @session_player_amount)

    {:noreply, new_state}
  end

  def handle_info(:check_capacity, %{players: players} = state) when length(players) >= @session_player_amount do
    {:ok, game_pid, game_config} = start_game()
    players = consume_and_notify_players(state.players, state, game_pid, game_config, @session_player_amount)
    new_session_ref = make_ref()
    Process.send_after(self(), {:check_timeout, new_session_ref}, @start_game_timeout_ms)
    {:noreply, %{state | players: players, session: new_session_ref, curent_lobby_players: 0}}
  end

  def handle_info(:check_capacity, state) do
    {:noreply, state}
  end

  ####################
  # Internal helpers #
  ####################
  defp start_game() do
    {:ok, game_pid} = RunnerSupervisor.start_child()
    {:ok, game_config} = RunnerSupervisor.Runner.get_config(game_pid)
    {:ok, game_pid, game_config}
  end

  defp consume_and_notify_players(remaining_players, _, _, _, 0) do
    remaining_players
  end

  defp consume_and_notify_players([], _, _, _, _) do
    []
  end

  defp consume_and_notify_players([{_, client_pid} | rest_players], state, game_pid, game_config, count) do
    Process.send(client_pid, {:preparing_game, game_pid, game_config}, [])
    Process.send(client_pid, {:notify_players_amount, @session_player_amount, @session_player_amount}, [])
    consume_and_notify_players(rest_players, state, game_pid, game_config, count - 1)
  end

  defp notify_players_amount(%{curent_lobby_players: amount, players: players}, capacity) do
    players
    |> Enum.each(fn {_, client_pid} ->
      Process.send(client_pid, {:notify_players_amount, amount, capacity}, [])
    end)
  end

  defp trigger_bots(bot_count, game_pid) when bot_count > 0 do
    {:ok, game_config_json} = Application.app_dir(:dark_worlds_server, "priv/config.json") |> File.read()
    config = Jason.decode!(game_config_json)

    payload =
      Jason.encode!(%{game_id: Communication.pid_to_external_id(game_pid), bot_count: bot_count, config: config})

    headers = [{"content-type", "application/json"}]
    bot_url = Application.fetch_env!(:dark_worlds_server, DarkWorldsServer.Bot) |> Keyword.get(:bot_server_url)
    {:ok, %{status: 201}} = Tesla.post("#{bot_url}/api/bot", payload, headers: headers)
  end

  defp trigger_bots(_, _) do
    :ok
  end
end
