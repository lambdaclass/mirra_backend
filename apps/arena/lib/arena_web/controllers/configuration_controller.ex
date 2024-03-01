defmodule ArenaWeb.ConfigurationController do
  use ArenaWeb, :controller

  alias Arena.Configuration

  def edit(conn, _params) do
    base_config = Configuration.read_base_json_game_config()
    config_json = Configuration.read_json_game_config()
    rows = Enum.count(String.split(config_json, "\n"))

    conn
    |> put_layout(false)
    |> render("edit.html", config_json: config_json, base_config: base_config, rows: rows)
  end

  def update(conn, %{"config" => config_json, "base_config" => base_config}) do
    rows = Enum.count(String.split(config_json, "\n"))

    case Configuration.update_config(config_json) do
      :ok ->
        conn
        |> put_layout(false)
        |> render("edit.html",
          config_json: config_json,
          base_config: base_config,
          rows: rows,
          updated: true
        )

      {:error, reason} ->
        conn
        |> put_layout(false)
        |> render("edit.html",
          config_json: config_json,
          base_config: base_config,
          rows: rows,
          error_reason: reason
        )
    end
  end
end
