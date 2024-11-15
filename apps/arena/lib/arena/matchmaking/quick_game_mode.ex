defmodule Arena.Matchmaking.QuickGameMode do
  @moduledoc false
  alias Arena.Utils
  alias Ecto.UUID

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
    "Thomas",
    "Timmy",
    "Pablito",
    "Nicolino",
    "Cangrejo",
    "Mansito"
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
    create_game_for_clients([{client_id, character_name, player_name, from_pid}], %{
      bots_enabled: true,
      zone_enabled: false
    })

    {:reply, :ok, state}
  end

  def handle_info(:start_game, state) do
    {game_clients, remaining_clients} = Enum.split(state.clients, Application.get_env(:arena, :players_needed_in_match))
    create_game_for_clients(game_clients)

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

  defp get_bot_clients(missing_clients) do
    characters =
      Arena.Configuration.get_game_config()
      |> Map.get(:characters)
      |> Enum.filter(fn character -> character.active end)

    Enum.map(1..missing_clients//1, fn i ->
      client_id = UUID.generate()

      {client_id, Enum.random(characters).name, Enum.at(@bot_names, i), nil}
    end)
  end

  defp spawn_bot_for_player(bot_clients, game_id) do
    Enum.each(bot_clients, fn {bot_client, _, _, _} ->
      send(self(), {:spawn_bot_for_player, bot_client, game_id})
    end)
  end

  # Receives a list of clients.
  # Fills the given list with bots clients, creates a game and tells every client to join that game.
  defp create_game_for_clients(clients, game_params \\ %{}) do
    # We will spawn bots in quick-game matches.
    # Check https://github.com/lambdaclass/mirra_backend/pull/951 to know how to restore former behavior.
    bot_clients = get_bot_clients(Application.get_env(:arena, :players_needed_in_match) - Enum.count(clients))

    {:ok, game_pid} =
      GenServer.start(Arena.GameUpdater, %{
        clients: clients,
        bot_clients: bot_clients,
        game_params: game_params |> Map.put(:game_mode, :QUICK_GAME)
      })

    game_id = game_pid |> :erlang.term_to_binary() |> Base58.encode()

    spawn_bot_for_player(bot_clients, game_id)

    Enum.each(clients, fn {_client_id, _character_name, _player_name, from_pid} ->
      Process.send(from_pid, {:join_game, game_id}, [])
      Process.send(from_pid, :leave_waiting_game, [])
    end)
  end
end
