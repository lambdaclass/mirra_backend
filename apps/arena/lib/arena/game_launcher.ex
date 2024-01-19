defmodule Arena.GameLauncher do
  @moduledoc false

  use GenServer

  # Amount of clients needed to start a game
  @clients_needed 50

  # API
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def join(client_id) do
    GenServer.call(__MODULE__, {:join, client_id})
  end

  # Callbacks
  @impl true
  def init(_) do
    Process.send_after(self(), :launch_game?, 300)
    {:ok, %{clients: []}}
  end

  @impl true
  def handle_call({:join, client_id}, {from_pid, _}, %{clients: clients} = state) do
    {:reply, :ok, %{state | clients: clients ++ [{client_id, from_pid}]}}
  end

  @impl true
  def handle_info(:launch_game?, %{clients: clients} = state) do
    Process.send_after(self(), :launch_game?, 300)

    if length(clients) >= @clients_needed do
      Process.send(self(), :start_game, [])
    end

    {:noreply, state}
  end

  def handle_info(:start_game, state) do
    {game_clients, remaining_clients} = Enum.split(state.clients, @clients_needed)

    {:ok, game_pid} = GenServer.start(Arena.GameUpdater, %{clients: game_clients})

    game_id = game_pid |> :erlang.term_to_binary() |> Base58.encode()

    Enum.each(game_clients, fn {_client_id, from_pid} ->
      Process.send(from_pid, {:join_game, game_id}, [])
      Process.send(from_pid, :leave_waiting_game, [])
    end)

    {:noreply, %{state | clients: remaining_clients}}
  end
end
