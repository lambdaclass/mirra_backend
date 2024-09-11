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
    |> text(Application.spec(:arena, :vsn))
  end

  def update_central(conn, %{"gateway_url" => gateway_url}) do
    System.put_env("GATEWAY_URL", gateway_url)

    conn
    |> put_status(:ok)
    |> text(gateway_url)
  end
end
