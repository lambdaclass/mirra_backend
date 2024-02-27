defmodule ArenaWeb.ConfigurationController do
  use ArenaWeb, :controller

  def edit(conn, _params) do
    config_json = Arena.Configuration.get_json_game_config()
    rows = Enum.count(String.split(config_json, "\n"))

    conn
    |> put_layout(false)
    |> render("edit.html", config_json: config_json, rows: rows)
  end
end
