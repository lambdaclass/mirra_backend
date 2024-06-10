defmodule Arena.GameLauncher do
  @moduledoc false
  alias Arena.Utils
  alias Ecto.UUID

  use GenServer

  # How long a queue can exist for before we launch and fill slots with bots
  @queue_lifetime_ms 10_000

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

  def leave(client_id) do
    GenServer.call(__MODULE__, {:leave, client_id})
  end

  # Callbacks
  @impl true
  def init(_) do
    Process.send_after(self(), :launch_matches, 1000)
    {:ok, %{clients: %{}, batch_start_at: 0, queues: []}}
  end

  @impl true
  def handle_call({:join, client_id, character_name, player_name}, {from_pid, _}, state) do
    prestige = get_prestige(client_id, character_name)
    queues = put_in_queue(state.queues, client_id, prestige)
    clients = Map.put(state.clients, client_id, {client_id, character_name, player_name, from_pid})
    {:reply, :ok, %{state | clients: clients, queues: queues}}
  end

  def handle_call({:leave, client_id}, _, state) do
    clients = Enum.reject(state.clients, fn {id, _, _, _} -> id == client_id end)
    {:reply, :ok, %{state | clients: clients}}
  end

  @impl true
  def handle_call({:join_quick_game, client_id, character_name, player_name}, {from_pid, _}, state) do
    create_game_for_clients([{client_id, character_name, player_name, from_pid}])

    {:reply, :ok, state}
  end

  @impl true
  def handle_info(:launch_matches, state) do
    Process.send_after(self(), :launch_matches, 1000)

    {queues, client_groups} = take_ready_queues(state.queues, Application.get_env(:arena, :players_needed_in_match))

    clients =
      Enum.reduce(client_groups, state.clients, fn client_ids, clients_acc ->
        Map.take(clients_acc, client_ids)
        |> Map.values()
        |> create_game_for_clients()

        Map.drop(clients_acc, client_ids)
      end)

    queues =
      expand_queues(queues)
      |> merge_queues()

    {:noreply, %{state | queues: queues, clients: clients}}
  end

  def handle_info({:spawn_bot_for_player, bot_client, game_id}, state) do
    spawn(fn ->
      Finch.build(:get, Utils.get_bot_connection_url(game_id, bot_client))
      |> Finch.request(Arena.Finch)
    end)

    {:noreply, state}
  end

  defp get_bot_clients(missing_clients) do
    characters =
      Arena.Configuration.get_game_config()
      |> Map.get(:characters)
      |> Enum.filter(fn character -> character.active end)

    Enum.map(1..missing_clients//1, fn i ->
      client_id = UUID.generate()

      {client_id, Enum.random(characters).name, Enum.at(@bot_names, i), nil}
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
    bot_clients = get_bot_clients(Application.get_env(:arena, :players_needed_in_match) - Enum.count(clients))

    {:ok, game_pid} =
      GenServer.start(Arena.GameUpdater, %{
        clients: clients,
        bot_clients: bot_clients
      })

    game_id = game_pid |> :erlang.term_to_binary() |> Base58.encode()

    spawn_bot_for_player(bot_clients, game_id)

    Enum.each(clients, fn {_client_id, _character_name, _player_name, from_pid} ->
      Process.send(from_pid, {:join_game, game_id}, [])
      Process.send(from_pid, :leave_waiting_game, [])
    end)
  end

  ## TODO: this is actually broken (will always be 0) because client_id is google_user_id and CharacterPrestige expects user_id
  ##  No point in fixing this right now, it should be addressed as part of https://github.com/lambdaclass/mirra_backend/issues/640
  defp get_prestige(client_id, character) do
    gateway_url = Application.get_env(:arena, :gateway_url)
    path = "/curse/users/#{client_id}/prestige/#{character}"

    result =
      Finch.build(:get, "#{gateway_url}#{path}", [{"content-type", "application/json"}])
      |> Finch.request(Arena.Finch)

    case result do
      {:ok, %{status: 200, body: body}} ->
        response = Jason.decode!(body)
        response["prestige"]

      _ ->
        ## TODO: we probably want to log something here
        0
    end
  end

  defp put_in_queue(queues, client_id, prestige) do
    put_in_queue(queues, [], client_id, prestige)
  end

  defp put_in_queue([%{first: first, last: last} = queue | rest], seen_q, client_id, prestige)
       when first <= prestige and prestige <= last do
    queue = %{queue | clients: [client_id | queue.clients]}
    seen_q ++ [queue | rest]
  end

  defp put_in_queue(
         [%{last: current_last} = current_queue, %{first: next_first} = next_queue | rest],
         seen_q,
         client_id,
         prestige
       )
       when current_last < prestige and prestige < next_first do
    new_queue = new_queue(client_id, current_queue.clients, prestige)
    seen_q ++ [current_queue, new_queue, next_queue | rest]
  end

  defp put_in_queue([], seen_q, client_id, prestige) do
    new_queue = new_queue(client_id, prestige)
    seen_q ++ [new_queue]
  end

  defp put_in_queue([current_queue | rest], seen_q, client_id, prestige) do
    seen_q = seen_q ++ [current_queue]
    put_in_queue(rest, seen_q, client_id, prestige)
  end

  defp new_queue(client_id, clients \\ [], base) do
    created_at = System.monotonic_time(:millisecond)
    margin = calculate_margin(base)
    %{clients: [client_id | clients], first: base - margin, last: base + margin, created_at: created_at}
  end

  defp calculate_margin(base) when base < 100, do: 10
  defp calculate_margin(base) when base < 500, do: trunc(base * 0.1)
  defp calculate_margin(base), do: trunc(base * 0.05)

  defp merge_queues(queues) do
    merge_queues(queues, [])
  end

  defp merge_queues([current_q, next_q | rest], acc) do
    range_1 = Range.new(current_q.first, current_q.last)
    range_2 = Range.new(next_q.first, next_q.last)

    case Range.disjoint?(range_1, range_2) do
      true ->
        merge_queues([next_q | rest], acc ++ [current_q])

      false ->
        clients = current_q.clients ++ next_q.clients
        created_at = min(current_q.created_at, next_q.created_at)
        merged = %{clients: clients, first: current_q.first, last: next_q.last, created_at: created_at}
        merge_queues(rest, acc ++ [merged])
    end
  end

  defp merge_queues(rest, acc) do
    acc ++ rest
  end

  defp take_ready_queues(queues, players_needed) do
    Enum.reduce(queues, {[], []}, fn queue, {remaining_queues, taken_clients} ->
      now = System.monotonic_time(:millisecond)
      queue_size = length(queue.clients)
      queue_time = now - queue.created_at

      cond do
        queue_size > players_needed ->
          {matched_clients, remaining_clients} = Enum.split(queue.clients, players_needed)
          queue = %{queue | clients: remaining_clients, created_at: now}
          {remaining_queues ++ [queue], [matched_clients | taken_clients]}

        queue_size == players_needed or queue_time >= @queue_lifetime_ms ->
          {remaining_queues, [queue.clients | taken_clients]}

        true ->
          {remaining_queues ++ [queue], taken_clients}
      end
    end)
  end

  defp expand_queues(queues) do
    Enum.map(queues, fn queue ->
      margin = div(queue.last - queue.first, 2)
      %{queue | first: queue.first - margin, last: queue.last + margin}
    end)
  end
end
