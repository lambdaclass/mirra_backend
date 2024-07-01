defmodule Arena.GameTracker do
  @moduledoc """
  This module is in charge of tracking the different game changes that we consider
  datapoints and use for quests, analytics, etc.

  `GameTracker` will behave similar to a metrics collector, but with a push model rather than pull.
  Games will push the data to it and at the end GameTracker will push the data to Gateway for storing
  """
  use GenServer

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def start_tracking(match_id, client_to_player_map, players, human_clients) do
    GenServer.call(__MODULE__, {:start_tracking, match_id, client_to_player_map, players, human_clients})
  end

  def finish_tracking(match_pid, winner_id) do
    GenServer.cast(__MODULE__, {:finish_tracking, match_pid, winner_id})
  end

  @type player_id :: pos_integer()
  @type bounty_quest_id :: binary()
  @type player :: %{id: player_id(), character_name: binary()}
  @type event ::
          {:kill, player(), player()}
          | {:damage_taken, player_id(), non_neg_integer()}
          | {:damage_done, player_id(), non_neg_integer()}
          | {:heal, player_id(), non_neg_integer()}
          | {:kill_by_zone, player_id()}
          | {:select_bounty, player_id(), bounty_quest_id()}

  @spec push_event(pid(), event()) :: :ok
  def push_event(match_pid, event) do
    GenServer.cast(__MODULE__, {:push_event, match_pid, event})
  end

  ##########################
  # Callbacks
  ##########################
  @impl true
  def init(_) do
    {:ok, %{matches: %{}}}
  end

  @impl true
  def handle_call({:start_tracking, match_id, client_to_player_map, players, human_clients}, {match_pid, _}, state) do
    player_to_client =
      Map.new(client_to_player_map, fn {client_id, player_id} -> {player_id, client_id} end)

    players =
      Map.new(players, fn {_, player} ->
        player_data = %{
          id: player.id,
          controller: if(Enum.member?(human_clients, player_to_client[player.id]), do: :human, else: :bot),
          character: player.aditional_info.character_name,
          kills: [],
          death: nil,
          damage_taken: 0,
          damage_done: 0,
          health_healed: 0,
          killed_by_bot: false,
          bounty_quest_id: nil
        }

        {player.id, player_data}
      end)

    match_state = %{
      match_id: match_id,
      start_at: System.monotonic_time(:millisecond),
      players: players,
      player_to_client: player_to_client,
      position_on_death: map_size(players)
    }

    state = put_in(state, [:matches, match_pid], match_state)
    {:reply, :ok, state}
  end

  @impl true
  def handle_cast({:finish_tracking, match_pid, winner_id}, state) do
    match_data = get_in(state, [:matches, match_pid])
    results = generate_results(match_data, winner_id)
    payload = Jason.encode!(%{results: results})
    send_request("/curse/match/#{match_data.match_id}", payload)
    matches = Map.delete(state.matches, match_pid)
    {:noreply, %{state | matches: matches}}
  end

  def handle_cast({:push_event, match_pid, event}, state) do
    case get_in(state, [:matches, match_pid]) do
      nil ->
        {:noreply, state}

      match_data ->
        updated_data = update_data(match_data, event)
        state = put_in(state, [:matches, match_pid], updated_data)
        {:noreply, state}
    end
  end

  @impl true
  def handle_info({:retry_request, path, payload, backoff}, state) do
    send_request(path, payload, backoff)
    {:noreply, state}
  end

  defp update_data(data, {:kill, killer, victim}) do
    data
    |> update_in([:players, killer.id, :kills], fn kills -> kills ++ [victim.character_name] end)
    |> put_in([:players, victim.id, :death], killer.character_name)
    |> put_in([:players, victim.id, :killed_by_bot], get_in(data, [:players, killer.id, :controller]) == :bot)
    |> put_in([:players, victim.id, :position], data.position_on_death)
    |> put_in([:position_on_death], data.position_on_death - 1)
  end

  defp update_data(data, {:kill_by_zone, victim_id}) do
    data
    |> put_in([:players, victim_id, :death], "zone")
    |> put_in([:players, victim_id, :killed_by_bot], false)
    |> put_in([:players, victim_id, :position], data.position_on_death)
    |> put_in([:position_on_death], data.position_on_death - 1)
  end

  defp update_data(data, {:damage_taken, player_id, amount}) do
    update_in(data, [:players, player_id, :damage_taken], fn damage_taken -> damage_taken + amount end)
  end

  defp update_data(data, {:damage_done, player_id, amount}) do
    update_in(data, [:players, player_id, :damage_done], fn damage_done -> damage_done + amount end)
  end

  defp update_data(data, {:heal, player_id, amount}) do
    update_in(data, [:players, player_id, :health_healed], fn health_healed -> health_healed + amount end)
  end

  defp update_data(data, {:select_bounty, player_id, bounty_quest_id}) do
    put_in(data, [:players, player_id, :bounty_quest_id], bounty_quest_id)
  end

  defp generate_results(match_data, winner_id) do
    duration = System.monotonic_time(:millisecond) - match_data.start_at

    Enum.filter(match_data.players, fn {_player_id, player_data} -> player_data.controller == :human end)
    |> Enum.map(fn {_player_id, player_data} ->
      %{
        user_id: get_in(match_data, [:player_to_client, player_data.id]),
        ## TODO: way to track `abandon`, currently a bot taking over will endup with a result
        ##    GameUpdater should send an event when the abandon happens to mark the player
        ##    https://github.com/lambdaclass/mirra_backend/issues/601
        result: if(player_data.id == winner_id, do: "win", else: "loss"),
        kills: length(player_data.kills),
        ## TODO: this only works because you can only die once
        ##    https://github.com/lambdaclass/mirra_backend/issues/601
        deaths: if(player_data.death == nil, do: 0, else: 1),
        character: player_data.character,
        position: get_player_position(player_data, winner_id, match_data),
        damage_taken: player_data.damage_taken,
        damage_done: player_data.damage_done,
        health_healed: player_data.health_healed,
        killed_by: player_data.death,
        killed_by_bot: player_data.killed_by_bot,
        duration_ms: duration,
        bounty_quest_id: player_data.bounty_quest_id
      }
    end)
  end

  defp send_request(path, payload, backoff \\ 0) do
    gateway_url = Application.get_env(:arena, :gateway_url)

    result =
      Finch.build(:post, "#{gateway_url}#{path}", [{"content-type", "application/json"}], payload)
      ## We might want to change this to `Finch.async_request/2`, but let's measure the impact first
      |> Finch.request(Arena.Finch)

    case result do
      {:ok, %Finch.Response{status: 201}} ->
        :ok

      ## TODO: need to figure out user not found to prevent retrying in that case
      _else_error ->
        Process.send_after(self(), {:retry_request, path, payload, backoff + 1}, backoff * 500)
    end
  end

  def get_player_position(%{id: winner_id}, winner_id, _match_data), do: winner_id
  def get_player_position(%{position: position}, _winner_id, _match_data), do: position
  # Default case for timeouts
  def get_player_position(_player_info, _winner_id, match_data), do: match_data.position_on_death
end
