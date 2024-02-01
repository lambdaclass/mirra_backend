defmodule ArenaWeb.HealthController do
  use ArenaWeb, :controller

  def check(conn, _params) do
    conn
    |> put_status(:ok)
    |> text("ok")
  end
end
