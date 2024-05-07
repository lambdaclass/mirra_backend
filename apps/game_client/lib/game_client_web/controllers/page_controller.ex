defmodule GameClientWeb.PageController do
  use GameClientWeb, :controller

  def home(conn, _params) do
    current_user_id = get_session(conn, :user_id)
    user_id = current_user_id || Ecto.UUID.generate()
    render(conn, :home, current_user_id: current_user_id, user_id: user_id)
  end

  def select_character(conn, %{"user_id" => user_id, "character" => character, "game_mode" => game_mode}) do
    redirect(conn, to: ~p"/board/#{user_id}/#{character}/player_name/#{game_mode}")
  end
end
