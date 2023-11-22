defmodule DarkWorldsServer.RunnerSupervisor do
  @moduledoc """
  Game Runner Supervisor
  """
  use DynamicSupervisor

  alias DarkWorldsServer.RunnerSupervisor.PlayerTracker
  alias DarkWorldsServer.RunnerSupervisor.RequestTracker
  alias DarkWorldsServer.RunnerSupervisor.Runner

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def start_child(bot_count) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {Runner, %{bot_count: bot_count}}
    )
  end

  @impl true
  def init(_opts) do
    RequestTracker.create_table()
    PlayerTracker.create_table()
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def list_runners_pids() do
    __MODULE__
    |> DynamicSupervisor.which_children()
    |> Enum.filter(fn children ->
      case children do
        {:undefined, pid, :worker, [Runner]} when is_pid(pid) -> true
        _ -> false
      end
    end)
    |> Enum.map(fn {_, pid, _, _} -> pid end)
  end
end
