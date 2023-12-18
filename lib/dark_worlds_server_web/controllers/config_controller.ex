defmodule DarkWorldsServerWeb.ConfigController do
  use DarkWorldsServerWeb, :controller

  def clean_import(conn, _assigns) do
    {:ok, result} = Utils.Config.clean_import()
    put_status(conn, 200) |> json(result)
  end
end
