defmodule Arena.GameLauncher do
  @moduledoc false
  alias Ecto.UUID

  use GenServer

  # Amount of clients needed to start a game
  @clients_needed 2
  # Time to wait to start game with any amount of clients
  @start_timeout_ms 1000

  # API
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def join(client_id, character_name) do
    GenServer.call(__MODULE__, {:join, client_id, character_name})
  end

  # Callbacks
  @impl true
  def init(_) do
    Process.send_after(self(), :launch_game?, 300)
    {:ok, %{clients: [], batch_start_at: 0}}
  end

  @impl true
  def handle_call({:join, client_id, character_name}, {from_pid, _}, %{clients: clients} = state) do
    batch_start_at = maybe_make_batch_start_at(state.clients, state.batch_start_at)

    {:reply, :ok,
     %{
       state
       | batch_start_at: batch_start_at,
         clients: clients ++ [{client_id, character_name, from_pid}]
     }}
  end

  @impl true
  def handle_info(:launch_game?, %{clients: clients} = state) do
    Process.send_after(self(), :launch_game?, 300)
    diff = System.monotonic_time(:millisecond) - state.batch_start_at

    if length(clients) >= @clients_needed or (diff >= @start_timeout_ms and length(clients) > 0) do
      send(self(), :start_game)
    end

    {:noreply, state}
  end

  def handle_info(:start_game, state) do
    IO.inspect("aber start game")

    {game_clients, remaining_clients} =
      Enum.split(state.clients, @clients_needed)
      |> spawn_bots(@clients_needed - Enum.count(state.clients))

    {:ok, game_pid} =
      GenServer.start(Arena.GameUpdater, %{
        clients: game_clients
      })

    game_id = game_pid |> :erlang.term_to_binary() |> Base58.encode()

    Enum.each(game_clients, fn {_client_id, _character_name, from_pid} ->
      Process.send(from_pid, {:join_game, game_id}, [])
      Process.send(from_pid, :leave_waiting_game, [])
    end)

    {:noreply, %{state | clients: remaining_clients}}
  end

  defp maybe_make_batch_start_at([], _) do
    System.monotonic_time(:millisecond)
  end

  defp maybe_make_batch_start_at([_ | _], batch_start_at) do
    batch_start_at
  end

  defp spawn_bots(clients, 0), do: clients

  defp spawn_bots({clients, remaining_clients}, missing_clients) do
    Enum.map(1..missing_clients, fn _ ->
      client_id = UUID.generate()

      Finch.build(:get, build_bot_url(client_id))
      |> Finch.request(Arena.Finch)
      |> IO.inspect(label: "aber response")

      {client_id, "muflus", "a"}
    end)

    {clients, remaining_clients}
  end

  defp build_bot_url(client_id) do
    # TODO remove this hardcode url when servers are implemented
    "http://localhost:5000/join/#{client_id}"
  end
end
