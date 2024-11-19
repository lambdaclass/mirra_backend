defmodule Arena.Matchmaking.QuickGameMode do
  @moduledoc false
  alias Arena.Matchmaking.GameLauncher
  alias Arena.Utils

  use GenServer

  # The available names for bots to enter a match, we should change this in the future
  @bot_names [
    "TheBlackSwordman",
    "SlashJava",
    "SteelBallRun",
    "Jeff",
    "Messi",
    "Stone Ocean",
    "Jeepers Creepers",
    "Bob",
    "El javo",
    "Alberso",
    "Thomas"
  ]

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

    GameLauncher.create_game_for_clients([client], %{bots_enabled: true, zone_enabled: false})

    {:reply, :ok, state}
  end

  def handle_info(:start_game, state) do
    {game_clients, remaining_clients} = Enum.split(state.clients, Application.get_env(:arena, :players_needed_in_match))
    GameLauncher.create_game_for_clients(game_clients)

    {:noreply, %{state | clients: remaining_clients}}
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
