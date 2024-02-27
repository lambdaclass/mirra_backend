defmodule ArenaWeb.ConfigurationController do
  use ArenaWeb, :controller

  def edit(conn, _params) do
    config_json = Arena.Configuration.get_json_game_config()
    rows = Enum.count(String.split(config_json, "\n"))

    conn
    |> put_layout(false)
    |> render("edit.html", config_json: config_json, rows: rows)
  end

  def update(conn, %{"config" => config_json}) do
    File.write!(Application.app_dir(:arena, "priv/config.json"), config_json)
    rows = Enum.count(String.split(config_json, "\n"))

    conn
    |> put_layout(false)
    |> render("edit.html", config_json: config_json, rows: rows, updated: true)
  end
end
