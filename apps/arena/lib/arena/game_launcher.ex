defmodule Arena.GameLauncher do
  @moduledoc false
  alias Ecto.UUID

  use GenServer
  require Logger

  # Amount of clients needed to start a game
  @clients_needed 10
  # Time to wait to start game with any amount of clients
  @start_timeout_ms 10_000
  # The available names for bots to enter a match, we should change this in the future
  @bot_names [
    "TheBlackSwordman",
    "SlashJava",
    "SteelBallRun",
    "Jeff",
    "Thomas",
    "Stone Ocean",
    "Jeepers Creepers",
    "Bob",
    "El javo",
    "Alberso",
    "Messi"
  ]

  # API
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def join(client_id, character_name, player_name) do
    GenServer.call(__MODULE__, {:join, client_id, character_name, player_name})
  end

  # Callbacks
  @impl true
  def init(_) do
    Process.send_after(self(), :launch_game?, 300)
    create_ets_table(:games)
    {:ok, %{clients: [], batch_start_at: 0}}
  end

  @impl true
  def handle_call({:join, client_id, character_name, player_name}, {from_pid, _}, %{clients: clients} = state) do
    batch_start_at = maybe_make_batch_start_at(state.clients, state.batch_start_at)

    {:reply, :ok,
     %{
       state
       | batch_start_at: batch_start_at,
         clients: clients ++ [{client_id, character_name, player_name, from_pid}]
     }}
  end

  @impl true
  def handle_info(:launch_game?, %{clients: clients} = state) do
    Process.send_after(self(), :launch_game?, 300)
    if length(clients) > @clients_needed do
      send(self(), :start_game)
    end

    Logger.info("Games playing: #{:ets.info(:games, :size)}")



    # diff = System.monotonic_time(:millisecond) - state.batch_start_at

    # if length(clients) >= @clients_needed or (diff >= @start_timeout_ms and length(clients) > 0) do
    # end

    {:noreply, state}
  end

  def handle_info(:start_game, state) do
    {game_clients, remaining_clients} = Enum.split(state.clients, @clients_needed)

    bot_clients = get_bot_clients(@clients_needed - Enum.count(state.clients))

    {:ok, game_pid} =
      GenServer.start(Arena.GameUpdater, %{
        clients: game_clients ++ bot_clients
      })

    true = :ets.insert(:games, {game_pid, game_pid})

    spawn_bot_for_player(bot_clients, game_pid)

    game_id = game_pid |> :erlang.term_to_binary() |> Base58.encode()

    Enum.each(game_clients, fn {_client_id, _character_name, _player_name, from_pid} ->
      Process.send(from_pid, {:join_game, game_id}, [])
      Process.send(from_pid, :leave_waiting_game, [])
    end)

    {:noreply, %{state | clients: remaining_clients}}
  end

  def handle_info({:spawn_bot_for_player, bot_client, game_pid}, state) do
    Finch.build(:get, build_bot_url(game_pid, bot_client))
    |> Finch.request(Arena.Finch)

    {:noreply, state}
  end

  defp maybe_make_batch_start_at([], _) do
    System.monotonic_time(:millisecond)
  end

  defp maybe_make_batch_start_at([_ | _], batch_start_at) do
    batch_start_at
  end

  defp get_bot_clients(missing_clients) do
    Enum.map(1..missing_clients//1, fn i ->
      client_id = UUID.generate()

      {client_id, "h4ck", Enum.at(@bot_names, i), nil}
    end)
  end

  defp spawn_bot_for_player(bot_clients, game_pid) do
    Enum.each(bot_clients, fn {bot_client, _, _, _} ->
      send(self(), {:spawn_bot_for_player, bot_client, game_pid})
    end)
  end

  defp build_bot_url(game_pid, bot_client) do
    encoded_game_pid = game_pid |> :erlang.term_to_binary() |> Base58.encode()
    server_url = System.get_env("PHX_HOST") || "localhost"
    # TODO remove this hardcode url when servers are implemented
    bot_manager_host = System.get_env("BOT_MANAGER_HOST", "localhost")
    bot_manager_port = System.get_env("BOT_MANAGER_PORT", "4003")
    "http://#{bot_manager_host}:#{bot_manager_port}/join/#{server_url}/#{encoded_game_pid}/#{bot_client}"
  end

  defp create_ets_table(table_name) do
    case :ets.whereis(table_name) do
      :undefined -> :ets.new(table_name, [:set, :named_table, :public])
      _table_exists_already -> nil
    end
  end
end
