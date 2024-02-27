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
    rows = Enum.count(String.split(config_json, "\n"))

    case Arena.Configuration.update_config(config_json) do
      :ok ->
        conn
        |> put_layout(false)
        |> render("edit.html", config_json: config_json, rows: rows, updated: true)
      {:error, reason} ->
        conn
        |> put_layout(false)
        |> render("edit.html", config_json: config_json, rows: rows, error_reason: reason)
    end
  end
end
