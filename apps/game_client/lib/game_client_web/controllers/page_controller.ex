defmodule GameClientWeb.PageController do
  use GameClientWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def select_character(conn, %{"character" => character, "game_mode" => game_mode}) do
    redirect(conn, to: ~p"/board/#{Ecto.UUID.generate()}/#{character}/player_name/#{game_mode}")
  end
end
