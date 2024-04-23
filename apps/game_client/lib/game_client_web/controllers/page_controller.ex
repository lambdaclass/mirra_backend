defmodule GameClientWeb.PageController do
  use GameClientWeb, :controller
  alias GameClient.Users

  def home(conn, _params) do
    render(conn, :home, email: "Guest")
  end

  def home_user(conn, %{"user_id" => user_id}) do
    user_email = Users.get_user_email(user_id)
    render(conn, :home, email: user_email)
  end

  def select_character(conn, %{"character" => character, "game_mode" => game_mode}) do
    redirect(conn, to: ~p"/board/#{Ecto.UUID.generate()}/#{character}/player_name/#{game_mode}")
  end
end
