defmodule Gateway.Controllers.HealthController do
  @moduledoc """
  Controller for health check.
  """
  use Gateway, :controller

  def check(conn, _params) do
    conn
    |> put_status(:ok)
    |> text("ok")
  end

  def version(conn, _params) do
    arena_version = Application.spec(:arena, :vsn) |> to_string()
    configurator_version = GameBackend.Configuration.get_configuration_hash_version()

    conn
    |> put_status(:ok)
    |> text(arena_version <> "." <> configurator_version)
  end
end
