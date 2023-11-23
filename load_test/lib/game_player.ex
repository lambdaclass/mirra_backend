defmodule LoadTest.GamePlayer do
  use WebSockex, restart: :transient
  require Logger
  use Tesla

  alias LoadTest.Communication.Proto.LobbyEvent
  alias LoadTest.Communication.Proto.GameConfig
  alias LoadTest.Communication.Proto.BoardSize
  alias LoadTest.Communication.Proto.ClientAction
  alias LoadTest.Communication.Proto.RelativePosition
  alias LoadTest.PlayerSupervisor

  def move(player, :up), do: _move(player, :UP)
  def move(player, :down), do: _move(player, :DOWN)
  def move(player, :left), do: _move(player, :LEFT)
  def move(player, :right), do: _move(player, :RIGHT)

  def attack(player, :up), do: _attack(player, :UP)
  def attack(player, :down), do: _attack(player, :DOWN)
  def attack(player, :left), do: _attack(player, :LEFT)
  def attack(player, :right), do: _attack(player, :RIGHT)

  def attack_aoe(player, position) do
    %{
      "player" => player,
      "action" => "attack_aoe",
      "value" => %{"x" => position.x, "y" => position.y}
    }
    |> send_command()
  end

  defp _move(player, direction) do
    %ClientAction{action: :MOVE, direction: direction}
    |> send_command()
  end

  def teleport(player, position) do
    %{
      "player" => player,
      "action" => "teleport",
      "value" => %{"x" => position.x, "y" => position.y}
    }
    |> send_command()
  end

  defp _attack(player, direction) do
    %ClientAction{action: :ATTACK, direction: direction}
    |> send_command()
  end

  defp attack_aoe(%{x: x, y: y}) do
    %ClientAction{
      action: :ATTACK_AOE,
      position: %RelativePosition{
        x: x,
        y: y
      }
    }
    |> send_command()
  end

  def start_link({player_number, session_id, max_duration}) do
    ws_url = ws_url(session_id, player_number)

    WebSockex.start_link(ws_url, __MODULE__, %{
      player_number: player_number,
      session_id: session_id,
      max_duration: max_duration
    })
  end

  def handle_connect(_conn, state) do
    unless is_nil(state.max_duration) do
      Process.send_after(self(), :disconnect, state.max_duration, [])
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
    action = Enum.random([:move, :attack, :attack_aoe])

    # Melee attacks pretty much never ever land, but in general we have to rework how
    # both melee and aoe attacks work in general, so w/e
    case action do
      :move ->
        move(state.player_number, direction)

      :attack ->
        attack(state.player_number, direction)

      :attack_aoe ->
        random_x = Enum.random(0..100)
        random_y = Enum.random(0..100)
        attack_aoe(%{x: random_x, y: random_y})
    end

    Process.send_after(self(), :play, 30, [])
    {:ok, state}
  end

  defp send_command(command) do
    WebSockex.cast(self(), {:send, {:binary, ClientAction.encode(command)}})
  end

  defp ws_url(session_id, player_id) do
    host = PlayerSupervisor.server_host()

    case System.get_env("SSL_ENABLED") do
      "true" ->
        "wss://#{host}/play/#{session_id}/#{player_id}"

      _ ->
        "ws://#{host}/play/#{session_id}/#{player_id}"
    end
  end
end
