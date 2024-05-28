defmodule Arena.GameBountyCache do
  @moduledoc false
  use GenServer

  @update_interval_ms 30_000

  # API
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get_bounties() do
    GenServer.call(__MODULE__, :get_bounties)
  end

  # Callbacks

  @impl true
  def init(_) do
    send(self(), :update_bounties)
    {:ok, %{bounties: []}}
  end

  @impl true
  def handle_info(:update_bounties, state) do
    url = Application.get_env(:arena, :gateway_url)
    path = "/curse/get_bounties"

    result =
      Finch.build(:get, "#{url}#{path}")
      |> Finch.request(Arena.Finch)

    bounties =
      case result do
        {:ok, %{status: 200, body: body}} ->
          Jason.decode!(body, [{:keys, :atoms}])

        _ ->
          []
      end

    Process.send_after(__MODULE__, :update_bounties, @update_interval_ms)
    {:noreply, Map.put(state, :bounties, bounties)}
  end

  @impl true
  def handle_call(:get_bounties, {_from_pid, _}, state) do
    {:reply, state.bounties, state}
  end
end
