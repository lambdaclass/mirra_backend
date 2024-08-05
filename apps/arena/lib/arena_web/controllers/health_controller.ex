defmodule ArenaWeb.HealthController do
  use ArenaWeb, :controller

  def check(conn, _params) do
    conn
    |> put_status(:ok)
    |> text("ok")
  end

  def version(conn, _params) do
    conn
    |> put_status(:ok)
    |> text(Arena.MixProject.project()[:version])
  end
end
