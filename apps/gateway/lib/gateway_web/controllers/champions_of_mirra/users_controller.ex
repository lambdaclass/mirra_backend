defmodule GatewayWeb.ChampionsOfMirra.UsersController do
  @moduledoc """
  Controller for Champions Of Mirra requests involving users.

  No logic should be handled here. All logic should be handled through the ChampionsOfMirra app.
  """

  use GatewayWeb, :controller

  def create_user(conn, %{"username" => username}) do
    response = ChampionsOfMirra.Users.register(username)
    json(conn, response)
  end

  def get_user(conn, %{"user_id" => user_id}) do
    response = ChampionsOfMirra.Users.get_user(user_id)
    json(conn, response)
  end
end
