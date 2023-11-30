defmodule LoadTest.GamePlayer do
  use WebSockex, restart: :transient
  require Logger
  use Tesla

  alias LoadTest.Communication.Proto.LobbyEvent
  alias LoadTest.Communication.Proto.GameConfig
  alias LoadTest.Communication.Proto.BoardSize
  alias LoadTest.Communication.Proto.GameAction
  alias LoadTest.Communication.Proto.RelativePosition
  alias LoadTest.PlayerSupervisor

  defp dir_to_degrees(:up), do: 90
  defp dir_to_degrees(:down), do: 270
  defp dir_to_degrees(:left), do: 180
  defp dir_to_degrees(:right), do: 360

  defp _move(player, direction) do
    angle_deg = dir_to_degrees(direction)
    timestamp = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

    %GameAction{action_type: {:move, %{angle: angle_deg}}, timestamp: timestamp}
    |> send_command()
  end

  defp _basic_attack(player, direction) do
    angle_deg = dir_to_degrees(direction)
    timestamp = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

    %GameAction{
      action_type: {:use_skill, %{degrees: angle_deg, skill: "BasicAttack"}},
      timestamp: timestamp
    }
    |> send_command()
  end

  def start_link({player_number, session_id, max_duration_seconds}) do
    ws_url = ws_url(session_id, player_number)

    WebSockex.start_link(ws_url, __MODULE__, %{
      player_number: player_number,
      session_id: session_id,
      max_duration_seconds: max_duration_seconds
    })
  end

  def handle_connect(_conn, state) do
    unless is_nil(state.max_duration_seconds) do
      max_duration_ms = state.max_duration_seconds * 1000
      Process.send_after(self(), :disconnect, max_duration_ms, [])
    end

    {:ok, state}
  end

  def handle_frame({type, msg}, state) do
    # Logger.info("Received Message: #{inspect(msg)}")
    {:ok, state}
  end

  def handle_cast({:send, {type, msg} = frame}, state) do
    # Logger.info("Sending frame with payload: #{msg}")
    {:reply, frame, state}
  end

  def handle_info(:disconnect, state) do
    {:close, {1000, ""}, state}
    # WebSockex.cast(self(), {:close, {1000, ""}, state})
  end

  def handle_info(:play, state) do
    direction = Enum.random([:up, :down, :left, :right])
    action = Enum.random([:move, :attack])

    # Melee attacks pretty much never ever land, but in general we have to rework how
    # both melee and aoe attacks work in general, so w/e
    case action do
      :move ->
        _move(state.player_number, direction)

      :attack ->
        _basic_attack(state.player_number, direction)
    end

    Process.send_after(self(), :play, 30, [])
    {:ok, state}
  end

  defp send_command(command) do
    WebSockex.cast(self(), {:send, {:binary, GameAction.encode(command)}})
  end

  defp ws_url(game_id, player_id) do
    host = PlayerSupervisor.server_host()

    case System.get_env("SSL_ENABLED") do
      "true" ->
        "wss://#{host}/play/#{game_id}/#{player_id}/#{player_id}"

      _ ->
        "ws://#{host}/play/#{game_id}/#{player_id}/#{player_id}"
    end
  end
end
