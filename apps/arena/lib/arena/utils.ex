defmodule Arena.Utils do
  @moduledoc """
  Utils module.
  It contains utility functions like math functions.
  """

  alias Arena.Matchmaking

  @bot_prefixes [
    "Astro",
    "Blaze",
    "Lunar",
    "Nova",
    "Pixel",
    "Ember",
    "Turbo",
    "Echo",
    "Frost",
    "Zenith",
    "Apex",
    "Orbit",
    "Cyber",
    "Drift",
    "Vivid",
    "Solar",
    "Nimbus",
    "Quirk",
    "Bolt",
    "Hollow",
    "AllRed",
    "Rust",
    "Metal",
    "Golden",
    "Reverse",
    "Time",
    "Chromian",
    "Elegant",
    "Jealous",
    "Adorable",
    "Dangerous",
    "Charming",
    "Royal"
  ]
  @bot_suffixes [
    "Hopper",
    "Runner",
    "Flyer",
    "Rover",
    "Spark",
    "Skull",
    "Whisper",
    "Seeker",
    "Rider",
    "Chaser",
    "Strider",
    "Hunter",
    "Shadow",
    "Glimmer",
    "Wave",
    "Glow",
    "Wing",
    "Dash",
    "Fang",
    "Shade",
    "Elixir",
    "Cavalier",
    "Lord",
    "Socks",
    "Creator",
    "Suit",
    "Greed",
    "Gun",
    "Balloon",
    "Lawyer",
    "Elevator",
    "Spider",
    "Dream",
    "WashingMachine"
  ]

  def normalize(%{x: 0, y: 0}) do
    %{x: 0, y: 0}
  end

  def normalize(%{x: x, y: y} = direction) when x == 0.0 and y == 0.0 do
    direction
  end

  def normalize(%{x: x, y: y}) do
    length = :math.sqrt(x * x + y * y)
    %{x: x / length, y: y / length}
  end

  def increase_value_by_base_percentage(current_value, base_value, amount) when is_integer(current_value) do
    (current_value + base_value * amount)
    |> round()
  end

  def increase_value_by_base_percentage(current_value, base_value, amount) do
    current_value + base_value * amount
  end

  def get_bot_connection_url(game_id, bot_client) do
    server_url = System.get_env("PHX_HOST") || "localhost"
    bot_manager_host = System.get_env("BOT_MANAGER_HOST", "localhost:4003")
    protocol = get_correct_protocol(bot_manager_host)

    "#{protocol}#{bot_manager_host}/join/#{server_url}/#{game_id}/#{bot_client}"
  end

  defp get_correct_protocol("localhost" <> _host), do: "http://"
  defp get_correct_protocol(_host), do: "https://"

  def assign_teams_to_players(players, :team, game_params) do
    Enum.chunk_every(players, game_params.team_size)
    |> Enum.with_index(fn player_pair, index ->
      Enum.map(player_pair, fn player -> Map.put(player, :team, index) end)
    end)
    |> List.flatten()
  end

  def assign_teams_to_players(players, :solo, _game_params) do
    Enum.with_index(players, fn player, index ->
      Map.put(player, :team, index)
    end)
  end

  def assign_teams_to_players(players, _not_implemented), do: players

  def list_bot_names(amount) do
    prefixes = Enum.take_random(@bot_prefixes, amount)
    suffixes = Enum.take_random(@bot_suffixes, amount)

    generate_names(prefixes, suffixes)
  end

  defp generate_names([], []), do: []

  defp generate_names([prefix | prefixes], [suffix | suffixes]) do
    [prefix <> suffix | generate_names(prefixes, suffixes)]
  end

  # Time to wait to start game with any amount of clients
  def start_timeout_ms(), do: 4_000

  def message_queue_lengths() do
    [
      Matchmaking.DeathmatchMode,
      Matchmaking.DuoMode,
      Matchmaking.GameLauncher,
      Matchmaking.QuickGameMode,
      Matchmaking.TrioMode,
      Arena.GameBountiesFetcher,
      Arena.GameTracker,
      Arena.Bots.PathfindingGrid
    ]
    |> Enum.each(fn registered_name ->
      Process.whereis(registered_name)
      |> register_process_info()
    end)

    register_bots_queues()
    register_game_updater_queues()
  end

  defp register_process_info(nil), do: nil

  defp register_process_info(pid) do
    case Process.info(pid, [:message_queue_len, :registered_name]) do
      [message_queue_len: len, registered_name: name] -> register_queue_length(name, len)
      [message_queue_len: len] -> register_queue_length(pid, len)
      _ -> nil
    end
  end

  defp register_queue_length(name, len) do
    :telemetry.execute([:vm, :message_queue], %{length: len}, %{process: inspect(name)})
  end

  defp register_bots_queues() do
    Registry.select(BotRegistry, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2"}}]}])
    |> Enum.each(fn {_bot_id, pid} ->
      case Process.info(pid, [:message_queue_len]) do
        [message_queue_len: len] -> :telemetry.execute([:bots, :message_queue], %{length: len}, %{})
        _ -> nil
      end
    end)
  end

  defp register_game_updater_queues() do
    Registry.select(GameUpdaterRegistry, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2"}}]}])
    |> Enum.each(fn {_game_id, pid} ->
      case Process.info(pid, [:message_queue_len]) do
        [message_queue_len: len] -> :telemetry.execute([:game_updater, :message_queue], %{length: len}, %{})
        _ -> nil
      end
    end)
  end
end
