defmodule Gateway.Controllers.ArenaServersController do
  @moduledoc """
  Controller for health check.
  """
  use Gateway, :controller
  alias GameBackend.Configuration

  action_fallback Gateway.Controllers.FallbackController

  def list_arena_servers(conn, _params) do
    arena_servers =
      Configuration.list_active_arena_servers()

    conn
    |> send_resp(200, Jason.encode!(%{servers: arena_servers}))
  end
end
