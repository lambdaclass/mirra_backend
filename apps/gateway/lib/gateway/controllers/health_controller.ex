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
    conn
    |> put_status(:ok)
    |> text(Application.spec(:arena, :vsn))
  end
end
