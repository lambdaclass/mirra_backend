defmodule Arena.Matchmaking.DeathmatchMode do
  @moduledoc false
  alias Arena.Bots.BotSupervisor
  alias Arena.Matchmaking
  alias Arena.Utils
  alias Ecto.UUID

  use GenServer

  # 3 Mins
  # TODO: add this to the configurator https://github.com/lambdaclass/mirra_backend/issues/985

  # API
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def join(params) do
    GenServer.call(__MODULE__, {:join, params})
  end

  def leave(client_id) do
    GenServer.call(__MODULE__, {:leave, client_id})
  end

  # Callbacks
  @impl true
  def init(_) do
    Process.send_after(self(), :launch_game?, 300)
    Process.send_after(self(), :update_params, 30_000)
    {:ok, %{clients: [], batch_start_at: 0}}
  end

  @impl true
  def handle_call({:join, params}, {from_pid, _}, %{clients: clients} = state) do
    batch_start_at = maybe_make_batch_start_at(state.clients, state.batch_start_at)

    client = %{
      client_id: params.client_id,
      character_name: params.character_name,
      character_level: params.character_level,
      skin_name: params.skin_name,
      name: params.player_name,
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
    diff = System.monotonic_time(:millisecond) - state.batch_start_at

    state = Matchmaking.get_matchmaking_configuration(state, 1, "deathmatch")

    if Map.has_key?(state, :game_mode_configuration) &&
         (length(clients) >= state.current_map.amount_of_players or
            (diff >= Utils.start_timeout_ms() and length(clients) > 0)) do
      send(self(), :start_game)
    end

    {:noreply, state}
  end

  def handle_info(:start_game, state) do
    {game_clients, remaining_clients} =
      Enum.split(state.clients, state.current_map.amount_of_players)

    create_game_for_clients(game_clients, state.game_mode_configuration, state.current_map)

    next_map = Enum.random(state.game_mode_configuration.map_mode_params)

    {:noreply, %{state | clients: remaining_clients, current_map: next_map}}
  end

  def handle_info(:update_params, state) do
    game_mode_configuration =
      case Arena.Configuration.get_game_mode_configuration(1, "deathmatch") do
        {:error, _} ->
          state

        {:ok, game_mode_configuration} ->
          game_mode_configuration
      end

    Process.send_after(self(), :update_params, 30_000)
    {:noreply, Map.put(state, :game_mode_configuration, game_mode_configuration)}
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

      %{
        client_id: client_id,
        skin_name: "Basic",
        character_name: Enum.random(characters).name,
        character_level: 1,
        name: Enum.at(bot_names, i - 1),
        type: :bot
      }
    end)
  end

  # Receives a list of clients.
  # Fills the given list with bots clients, creates a game and tells every client to join that game.
  defp create_game_for_clients(clients, game_params, map) do
    game_params =
      Map.merge(game_params, %{
        game_mode: :DEATHMATCH
      })

    # We spawn bots only if there is one player
    bot_clients =
      case Enum.count(clients) do
        1 -> get_bot_clients(map.amount_of_players - Enum.count(clients))
        _ -> []
      end

    players = Utils.assign_teams_to_players(clients ++ bot_clients, :solo, game_params)

    {:ok, game_pid} =
      GenServer.start(Arena.GameUpdater, %{players: players, game_params: game_params, map_mode_params: map})

    game_id = game_pid |> :erlang.term_to_binary() |> Base58.encode()

    BotSupervisor.start_bots_for_game(bot_clients, game_id)

    Enum.each(clients, fn %{from_pid: from_pid} ->
      Process.send(from_pid, {:join_game, game_id}, [])
      Process.send(from_pid, :leave_waiting_game, [])
    end)
  end
end
