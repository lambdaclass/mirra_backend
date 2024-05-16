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

  ## TODO: define events structs or pattern
  ##    https://github.com/lambdaclass/mirra_backend/issues/601
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
          position: nil
        }

        {player.id, player_data}
      end)

    match_state = %{
      match_id: match_id,
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
    ## TODO: Handle errors and retry sending
    ##    https://github.com/lambdaclass/mirra_backend/issues/601
    send_request("/arena/match/#{match_data.match_id}", payload)

    matches = Map.delete(state.matches, match_pid)
    {:noreply, %{state | matches: matches}}
  end

  def handle_cast({:push_event, match_pid, event}, state) do
    state = update_in(state, [:matches, match_pid], fn data -> update_data(data, event) end)
    {:noreply, state}
  end

  defp update_data(data, {:kill, %{character_name: "Zone"}, victim}) do
    data
    |> put_in([:players, victim.id, :death], "Zone")
    |> put_in([:players, victim.id, :position], data.position_on_death)
    |> put_in([:position_on_death], data.position_on_death - 1)
  end

  defp update_data(data, {:kill, killer, victim}) do
    data
    |> update_in([:players, killer.id, :kills], fn kills -> kills ++ [victim.character_name] end)
    |> put_in([:players, victim.id, :death], killer.character_name)
    |> put_in([:players, victim.id, :position], data.position_on_death)
    |> put_in([:position_on_death], data.position_on_death - 1)
  end

  defp generate_results(match_data, winner_id) do
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
        position: player_data.position
      }
    end)
  end

  defp send_request(path, payload) do
    gateway_url = Application.get_env(:arena, :gateway_url)

    Finch.build(:post, "#{gateway_url}#{path}", [{"content-type", "application/json"}], payload)
    ## We might want to change this to `Finch.async_request/2`, but let's measure the impact first
    |> Finch.request(Arena.Finch)
  end
end
