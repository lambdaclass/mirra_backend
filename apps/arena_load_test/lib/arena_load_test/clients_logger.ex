defmodule ArenaLoadTest.ClientsLogger do
  @moduledoc false
  use GenServer
  require Logger

  # API
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  # Callbacks
  @impl true
  def init(_) do
    send(self(), :alive_clients_log)
    {:ok, %{}}
  end

  @impl true
  def handle_info(:alive_clients_log, state) do
    Logger.info("Clients waiting for a game: #{:ets.info(:clients, :size)}")
    Logger.info("Players in match: #{:ets.info(:players, :size)}")
    Process.send_after(self(), :alive_clients_log, 1_000)
    {:noreply, state}
  end
end
