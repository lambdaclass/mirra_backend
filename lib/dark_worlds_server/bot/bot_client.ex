defmodule DarkWorldsServer.Bot.BotClient do
  alias DarkWorldsServer.Communication
  alias DarkWorldsServer.Communication.Proto.TransitionGameEvent
  alias DarkWorldsServer.RunnerSupervisor.BotPlayer
  use WebSockex, restart: :temporary
  require Logger

  def start_link(%{game_id: game_id, config: config}) do
    client_id = UUID.uuid4()
    ws_url = Application.fetch_env!(:dark_worlds_server, DarkWorldsServer.Bot) |> Keyword.get(:game_server_url)
    WebSockex.start_link("#{ws_url}/play/#{game_id}/#{client_id}/2", __MODULE__, %{config: config}, [])
  end

  @impl true
  def handle_connect(_conn, state) do
    Logger.info("Connected #{inspect(self())}")
    NewRelic.increment_custom_metric("GameBackend/TotalBots", 1)
    {:ok, state}
  end

  @impl true
  def handle_frame({:binary, raw_msg}, state) do
    msg = TransitionGameEvent.decode(raw_msg)
    handle_msg(msg.old_game_event, state)
  end

  @impl true
  def handle_info({:move, angle}, state) do
    {:reply, {:binary, Communication.player_move(angle)}, state}
  end

  def handle_info({:use_skill, angle, skill}, state) do
    {:reply, {:binary, Communication.player_use_skill(skill, angle)}, state}
  end

  @impl true
  def handle_disconnect(%{reason: {:local, reason}}, state) do
    Logger.info("Local close with reason: #{inspect(reason)}")
    {:ok, state}
  end

  def handle_disconnect(disconnect_map, state) do
    super(disconnect_map, state)
  end

  @impl true
  def terminate(_reason, _state) do
    NewRelic.increment_custom_metric("GameBackend/TotalBots", -1)
    :ok
  end

  defp handle_msg(%{type: :PLAYER_JOINED, player_joined_id: player_id}, state) do
    {:ok, bot_pid} = BotPlayer.start_link(self(), state.config)
    BotPlayer.add_bot(bot_pid, player_id)
    state = Map.merge(state, %{bot_pid: bot_pid, player_id: player_id})
    {:ok, state}
  end

  defp handle_msg(%{type: :STATE_UPDATE} = game_state, state) do
    send(state.bot_pid, {:game_state, game_state})
    {:ok, state}
  end

  defp handle_msg(%{type: :GAME_FINISHED}, state) do
    GenServer.stop(state.bot_pid)
    {:close, state}
  end

  defp handle_msg(%{type: :PING_UPDATE}, state) do
    {:ok, state}
  end

  defp handle_msg(%{type: :GAME_STARTED}, state) do
    BotPlayer.toggle_bots(state.bot_pid, true)
    {:ok, state}
  end
end
