defmodule DarkWorldsServerWeb.BotController do
  use DarkWorldsServerWeb, :controller

  alias DarkWorldsServer.Bot.BotClientSupervisor

  plug :check_bot_server_enabled

  def create(conn, %{"game_id" => game_id, "bot_count" => bot_count, "config" => config}) do
    :ok = BotClientSupervisor.start_bot_clients(game_id, bot_count, config)
    put_status(conn, 201) |> json(%{})
  end

  def check_bot_server_enabled(conn, _options) do
    bot_server_enabled =
      Application.fetch_env!(:dark_worlds_server, DarkWorldsServer.RunnerSupervisor.Runner)
      |> Keyword.fetch!(:bot_server)

    if bot_server_enabled == :enabled do
      conn
    else
      put_status(conn, 409) |> halt()
    end
  end
end
