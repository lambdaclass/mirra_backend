defmodule DarkWorldsServerWeb.LobbyController do
  use DarkWorldsServerWeb, :controller

  alias DarkWorldsServer.Communication

  def new(conn, _params) do
    json(conn, %{})
  end

  def current_lobbies(conn, _params) do
    server_hash = Application.get_env(:dark_worlds_server, :information) |> Keyword.get(:version_hash)
    json(conn, %{lobbies: [], server_version: server_hash})
  end

  def join(conn, _params) do
    json(conn, %{lobby_id: Communication.pid_to_external_id(self())})
  end
end
