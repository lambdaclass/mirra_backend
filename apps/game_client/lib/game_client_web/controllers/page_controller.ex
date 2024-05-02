defmodule GameClientWeb.PageController do
  use GameClientWeb, :controller

  def home(conn, _params) do
    user_id = get_session(conn, :user_id)
    render(conn, :home, user_id: user_id)
  end

  def select_character(conn, %{"character" => character, "game_mode" => game_mode} = params) do
    user_id = params["user_id"] || Ecto.UUID.generate()
    redirect(conn, to: ~p"/board/#{user_id}/#{character}/player_name/#{game_mode}")
  end
end
