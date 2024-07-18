defmodule Arena.ServerSocketHandler do
  @moduledoc """
  Module that handles cowboy websocket requests
  """
  require Logger

  @behaviour :cowboy_websocket

  @impl true
  def init(req, _opts) do
    {:cowboy_websocket, req, %{}}
  end

  @impl true
  def websocket_init(state) do
    {:ok, state}
  end

  @impl true
  def websocket_info(_any, state) do
    {:ok, state}
  end

  @impl true
  def websocket_handle({:text, msg}, state) do
    handle_msg(Jason.decode!(msg), state)
  end

  defp handle_msg(%{"action" => "check_ping", "client_timestamp" => client_timestamp}, state) do
    now = DateTime.utc_now() |> DateTime.to_unix()
    Logger.info("Message received", %{server_timestamp: now, client_timestamp: client_timestamp})
    {:reply, {:text, Jason.encode!(%{action: "response_ping", server_timestamp: now, client_timestamp: client_timestamp})}, state}
  end
end
