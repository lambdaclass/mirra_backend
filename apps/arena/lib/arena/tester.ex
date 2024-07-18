defmodule Tester do
  @moduledoc """
  GameClient socket handler.
  It handles the communication with the server.
  """

  use WebSockex, restart: :transient
  require Logger

  def start_link() do
    host = "arena-brazil-testing.curseofmirra.com"
    ws_url = "wss://#{host}/testing"

    WebSockex.start_link(ws_url, __MODULE__, %{})
  end

  def handle_connect(_, state) do
    Logger.info("Game connected")
    send(self(), :check_ping)
    {:ok, state}
  end

  def handle_frame({:text, msg}, state) do
    msg = Jason.decode!(msg, keys: :atoms)
    metadata = Map.merge(msg, %{latency_ms: (msg.server_timestamp - msg.client_timestamp)})
    Logger.info("Received frame", metadata)
    {:ok, state}
  end

  def handle_info(:check_ping, state) do
    now = DateTime.utc_now() |> DateTime.to_unix()
    Logger.info("Sending check_ping", %{timestamp: now})
    Process.send_after(self(), :check_ping, 30)
    {:reply, {:text, Jason.encode!(%{"action" => "check_ping", "client_timestamp" => now})}, state}
  end

  def terminate(close_reason, _state) do
    Logger.info("Socket closed: #{inspect(close_reason)}")
    :ok
  end
end
