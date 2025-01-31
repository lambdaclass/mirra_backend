defmodule Arena.Matchmaking.PairMode do
  @moduledoc false
  alias Arena.Utils
  alias Ecto.UUID

  use GenServer

  # API
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def join(client_id, character_name, player_name) do
    GenServer.call(__MODULE__, {:join, client_id, character_name, player_name})
  end

  def leave(client_id) do
    GenServer.call(__MODULE__, {:leave, client_id})
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

    client = %{
      client_id: client_id,
      character_name: character_name,
      name: player_name,
      from_pid: from_pid,
      type: :human
    }

    {:reply, :ok,
     %{
       state
       | batch_start_at: batch_start_at,
         clients: clients ++ [client]
     }}
  end

  def handle_call({:leave, client_id}, _, state) do
    clients = Enum.reject(state.clients, fn %{client_id: id} -> id == client_id end)
    {:reply, :ok, %{state | clients: clients}}
  end

  @impl true
  def handle_info(:launch_game?, %{clients: clients} = state) do
    Process.send_after(self(), :launch_game?, 300)

    state =
      if Map.has_key?(state, :game_mode_configuration) do
        state
      else
        case Arena.Configuration.get_game_mode_configuration("pair", "battle_royale") do
          {:error, _} ->
            state

          {:ok, game_mode_configuration} ->
            # This is needed because we might not want to send a request every 300 seconds to the game backend
            Process.send_after(self(), :update_params, 5000)
            Map.put(state, :game_mode_configuration, game_mode_configuration)
        end
      end

    diff = System.monotonic_time(:millisecond) - state.batch_start_at

    if Map.has_key?(state, :game_mode_configuration) &&
         (length(clients) >= state.game_mode_configuration.amount_of_players or
            (diff >= Utils.start_timeout_ms() and length(clients) > 0)) do
      send(self(), :start_game)
    end

    {:noreply, state}
  end

  def handle_info(:start_game, state) do
    {game_clients, remaining_clients} = Enum.split(state.clients, state.game_mode_configuration.amount_of_players)
    create_game_for_clients(game_clients, state.game_mode_configuration)

    {:noreply, %{state | clients: remaining_clients}}
  end

  def handle_info(:update_params, state) do
    game_mode_configuration =
      case Arena.Configuration.get_game_mode_configuration("pair", "battle_royale") do
        {:error, _} ->
          state

        {:ok, game_mode_configuration} ->
          game_mode_configuration
      end

    Process.send_after(self(), :update_params, 5000)
    {:noreply, Map.put(state, :game_mode_configuration, game_mode_configuration)}
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
    characters =
      Arena.Configuration.get_game_config()
      |> Map.get(:characters)
      |> Enum.filter(fn character -> character.active end)

    bot_names = Utils.list_bot_names(missing_clients)

    Enum.map(1..missing_clients//1, fn i ->
      client_id = UUID.generate()

      %{client_id: client_id, character_name: Enum.random(characters).name, name: Enum.at(bot_names, i - 1), type: :bot}
    end)
  end

  defp spawn_bot_for_player(bot_clients, game_id) do
    Enum.each(bot_clients, fn %{client_id: bot_client_id} ->
      send(self(), {:spawn_bot_for_player, bot_client_id, game_id})
    end)
  end

  # Receives a list of clients.
  # Fills the given list with bots clients, creates a game and tells every client to join that game.
  defp create_game_for_clients(clients, game_params) do
    game_params = Map.put(game_params, :game_mode, :PAIR)

    bot_clients =
      if Enum.count(clients) < game_params.amount_of_players do
        get_bot_clients(game_params.amount_of_players - Enum.count(clients))
      else
        []
      end

    players = Utils.assign_teams_to_players(clients ++ bot_clients, :pair)

    {:ok, game_pid} = GenServer.start(Arena.GameUpdater, %{players: players, game_params: game_params})

    game_id = game_pid |> :erlang.term_to_binary() |> Base58.encode()

    spawn_bot_for_player(bot_clients, game_id)

    Enum.each(clients, fn %{from_pid: from_pid} ->
      Process.send(from_pid, {:join_game, game_id}, [])
      Process.send(from_pid, :leave_waiting_game, [])
    end)
  end
end
