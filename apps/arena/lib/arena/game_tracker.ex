defmodule Arena.GameTracker do
  @moduledoc """
  This module is in charge of tracking the different game changes that we consider
  datapoints and use for quests, analytics, etc.

  `GameTracker` will behave similar to a metrics collector, but with a push model rather than pull.
  Games will push the data to it and every X time it will push the data to Gateway for storing and updating quests
  """
  use GenServer

  @flush_interval_ms 10_000

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def start_tracking(match_id, client_to_player_map) do
    GenServer.call(__MODULE__, {:start_tracking, match_id, client_to_player_map})
  end
  def finish_tracking(match_pid, results) do
    GenServer.cast(__MODULE__, {:finish_tracking, match_pid, results})
  end

  ## TODO: define event struct
  def push_event(match_pid, event) do
    GenServer.cast(__MODULE__, {:push_event, match_pid, event})
  end

  ##########################
  # Callbacks
  ##########################
  @impl true
  def init(_) do
    state = %{matches: %{}}
    {:ok, state}
  end

  @impl true
  def handle_call({:start_tracking, match_id, client_to_player_map}, {match_pid, _}, state) do
    Process.send_after(self(), {:report, match_pid}, @flush_interval_ms)
    player_to_client = Map.new(client_to_player_map, fn {client_id, player_id} -> {player_id, client_id} end)
    players = Map.new(player_to_client, fn {player_id, user_id} -> {user_id, %{player_id: player_id, kills: [], death: nil}} end)
    state = put_in(state, [:matches, match_pid], %{match_id: match_id, players: players, player_to_client: player_to_client})
    {:reply, :ok, state}
  end

  @impl true
  ## TODO: a lot of things, final report and send to Gateway
  def handle_cast({:finish_tracking, match_pid, results}, state) do
    gateway_url = Application.get_env(:arena, :gateway_url)
    data = get_in(state, [:matches, match_pid])

    ## Final flush of match data
    ## TODO: Maybe this should be part of the final reporting
    encoded_data = :erlang.term_to_binary(data) |> :base64.encode()
    stats_payload = Jason.encode!(%{match_id: data.match_id, data: encoded_data})
    Finch.build(:post, "#{gateway_url}/arena/match_report", [{"content-type", "application/json"}], stats_payload)
    |> Finch.request(Arena.Finch)

    ## Send results
    payload = Jason.encode!(%{match_id: data.match_id, results: results})
    ## TODO: make sure to handle errors and retry sending
    Finch.build(:post, "#{gateway_url}/arena/match", [{"content-type", "application/json"}], payload)
    |> Finch.request(Arena.Finch)

    matches = Map.delete(state.matches, match_pid)
    {:noreply, %{state | matches: matches}}
  end

  def handle_cast({:push_event, match_pid, event}, state) do
    state = update_in(state, [:matches, match_pid], fn data -> update_data(data, event) end)
    {:noreply, state}
  end

  @impl true
  def handle_info({:report, match_pid}, state) do
    case get_in(state, [:matches, match_pid]) do
      nil ->
        {:noreply, state}

      data ->
        Process.send_after(self(), {:report, match_pid}, @flush_interval_ms)
        gateway_url = Application.get_env(:arena, :gateway_url)
        encoded_data = :erlang.term_to_binary(data) |> :base64.encode()
        payload = Jason.encode!(%{match_id: data.match_id, data: encoded_data})

        Finch.build(:post, "#{gateway_url}/arena/match_report", [{"content-type", "application/json"}], payload)
        ## We don't care about the result of this requests, if they fail it will be essentially retried on the next report
        ## We might want to change this to `Finch.async_request/2`, but let's measure the impact first
        |> Finch.request(Arena.Finch)

        {:noreply, state}
    end
  end

  defp update_data(data, {:kill, killer, victim}) do
    data
    |> update_in([:players, data.player_to_client[killer.id], :kills], fn kills -> kills ++ [victim.character_name] end)
    |> put_in([:players, data.player_to_client[victim.id], :death], killer.character_name)
  end
end
