defmodule Arena.Matchmaking.QuickGameMode do
  @moduledoc false
  alias Arena.Matchmaking.GameLauncher
  alias Arena.Utils

  use GenServer

  # API
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def join(client_id, character_name, player_name) do
    GenServer.call(__MODULE__, {:join, client_id, character_name, player_name})
  end

  def leave(_client_id) do
    :noop
  end

  # Callbacks
  @impl true
  def init(_) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:join, client_id, character_name, player_name}, {from_pid, _}, state) do
    client = %{
      client_id: client_id,
      character_name: character_name,
      name: player_name,
      from_pid: from_pid,
      type: :human
    }

    state =
      if Map.has_key?(state, :game_mode_configuration) do
        state
      else
        case Arena.Configuration.get_game_mode_configuration("quick-game", "battle_royale") do
          {:error, _} ->
            state

          {:ok, game_mode_configuration} ->
            # This is needed because we might not want to send a request every 300 seconds to the game backend
            Process.send_after(self(), :update_params, 5000)
            map = Enum.random(game_mode_configuration.map_mode_params)

            Map.put(state, :game_mode_configuration, game_mode_configuration)
            |> Map.put(:current_map, map)
        end
      end

    if Map.has_key?(state, :game_mode_configuration) do
      GameLauncher.create_game_for_clients([client], state.game_mode_configuration, state.current_map)
    end

    {:reply, :ok, state}
  end

  @impl true
  def handle_info({:spawn_bot_for_player, bot_client, game_id}, state) do
    spawn(fn ->
      Finch.build(:get, Utils.get_bot_connection_url(game_id, bot_client))
      |> Finch.request(Arena.Finch)
    end)

    {:noreply, state}
  end
end
