defmodule Gateway.Controllers.ArenaServersController do
  @moduledoc """
  Controller for health check.
  """
  use Gateway, :controller
  alias GameBackend.Configuration

  action_fallback Gateway.Controllers.FallbackController

  def list_arena_servers(conn, _params) do
    arena_servers =
      Configuration.list_arena_servers()
      |> Enum.map(fn arena_server ->
        %{
          id: arena_server.id,
          ip: arena_server.ip,
          url: arena_server.url,
          name: arena_server.name,
          status: arena_server.status,
          environment: arena_server.environment
        }
      end)

    conn
    |> send_resp(200, Jason.encode!(arena_servers))
  end
end
