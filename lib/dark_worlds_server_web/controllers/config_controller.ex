defmodule DarkWorldsServerWeb.ConfigController do
  use DarkWorldsServerWeb, :controller

  def config(conn, _assigns) do
    {:ok, config} = Utils.Config.get_config() |> Jason.encode(%{})
    send_resp(conn, 200, config)
  end

  def clean_import(conn, _assigns) do
    {:ok, result} = Utils.Config.clean_import()
    put_status(conn, 200) |> json(result)
  end
end
