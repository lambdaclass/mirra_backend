defmodule Arena.GameLauncher do
  @moduledoc false
  alias Arena.Utils
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
    "Messi",
    "Stone Ocean",
    "Jeepers Creepers",
    "Bob",
    "El javo",
    "Alberso",
    "Thomas"
  ]

  # API
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def join(client_id, character_name, player_name) do
    GenServer.call(__MODULE__, {:join, client_id, character_name, player_name})
  end

  def join_quick_game(client_id, character_name, player_name) do
    GenServer.call(__MODULE__, {:join_quick_game, client_id, character_name, player_name})
  end

  # Callbacks
  @impl true
  def init(_) do
    Process.send_after(self(), :launch_game?, 300)
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
  def handle_call({:join_quick_game, client_id, character_name, player_name}, {from_pid, _}, state) do
    create_game_for_clients([{client_id, character_name, player_name, from_pid}])

    {:reply, :ok, state}
  end

  @impl true
  def handle_info(:launch_game?, %{clients: clients} = state) do
    Process.send_after(self(), :launch_game?, 10)
    diff = System.monotonic_time(:millisecond) - state.batch_start_at

    if length(clients) >= @clients_needed or (diff >= @start_timeout_ms and length(clients) > 0) do
      send(self(), :start_game)
    end

    {:noreply, state}
  end

  def handle_info(:start_game, state) do
    {game_clients, remaining_clients} = Enum.split(state.clients, @clients_needed)
    create_game_for_clients(game_clients)

    {:noreply, %{state | clients: remaining_clients}}
  end

  def handle_info({:spawn_bot_for_player, bot_client, game_id}, state) do
    spawn(fn ->
      Finch.build(:get, Utils.get_bot_connection_url(game_id, bot_client))
      |> Finch.request(Arena.Finch)
    end)

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

  defp spawn_bot_for_player(bot_clients, game_id) do
    Enum.each(bot_clients, fn {bot_client, _, _, _} ->
      send(self(), {:spawn_bot_for_player, bot_client, game_id})
    end)
  end

  # Receives a list of clients.
  # Fills the given list with bots clients, creates a game and tells every client to join that game.
  defp create_game_for_clients(clients) do
    bot_clients = get_bot_clients(@clients_needed - Enum.count(clients))

    {:ok, game_pid} =
      GenServer.start(Arena.GameUpdater, %{
        clients: clients ++ bot_clients
      })

    game_id = game_pid |> :erlang.term_to_binary() |> Base58.encode()

    spawn_bot_for_player(bot_clients, game_id)

    Enum.each(clients, fn {_client_id, _character_name, _player_name, from_pid} ->
      Process.send(from_pid, {:join_game, game_id}, [])
      Process.send(from_pid, :leave_waiting_game, [])
    end)
  end
end
