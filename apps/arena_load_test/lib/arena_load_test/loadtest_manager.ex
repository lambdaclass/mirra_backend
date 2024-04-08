defmodule ArenaLoadTest.LoadtestManager do
  @moduledoc """
  Genserver that interacts with the running loadtest for the user needs.
  """
  use GenServer
  require Logger
  alias ArenaLoadTest.SocketSupervisor

  # API
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  # Callbacks
  @impl true
  def init(_) do
    {:ok, %{}}
  end

  @doc """
  Periodically prints in terminal the amount of websockets (in-game and in-queue).
  """
  @impl true
  def handle_info(:clients_log, state) do
    Logger.info("Clients waiting for a game: #{:ets.info(:clients, :size)}")
    Logger.info("Players in match: #{:ets.info(:players, :size)}")
    Process.send_after(self(), :clients_log, 1_000)
    {:noreply, state}
  end

  @doc """
  Finishes the running loadtest.
  """
  @impl true
  def handle_info(:loadtest_finished, state) do
    SocketSupervisor.terminate_children()
    Logger.info("Loadtest finished.")
    {:stop, :normal, state}
  end
end
