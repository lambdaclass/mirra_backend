defmodule GatewayWeb.ChampionsOfMirra.UsersController do
  use GatewayWeb, :controller

  def create_user(conn, %{"username" => username}) do
    response = ChampionsOfMirra.process_users(:create_user, username)
    json(conn, response)
  end

  def get_user(conn, %{"user_id" => user_id}) do
    response = ChampionsOfMirra.process_users(:get_user, user_id)
    json(conn, response)
  end
end
