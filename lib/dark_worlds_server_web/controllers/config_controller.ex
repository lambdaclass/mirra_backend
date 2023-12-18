defmodule DarkWorldsServerWeb.ConfigController do
  use DarkWorldsServerWeb, :controller
  alias DarkWorldsServer.Utils.Config

  def config(conn, _assigns) do
    {:ok, config} = Config.get_config() |> Jason.encode(%{})

    conn
    |> prepend_resp_headers([{"content-type", "application/json"}])
    |> send_resp(200, config)
  end

  def clean_import(conn, _assigns) do
    {:ok, result} = Config.clean_import()
    put_status(conn, 200) |> json(result)
  end
end
