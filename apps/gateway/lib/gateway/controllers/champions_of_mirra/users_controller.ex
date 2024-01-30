defmodule Gateway.ChampionsOfMirra.UsersController do
  @moduledoc """
  Controller for Champions Of Mirra requests involving users.

  No logic should be handled here. All logic should be handled through the ChampionsOfMirra app.
  """

  use Gateway, :controller

  def create_user(conn, %{"username" => username}) do
    ChampionsOfMirra.Users.register(username) |> Gateway.Utils.format_response(conn)
  end

  def get_id(conn, %{"username" => username}) do
    ChampionsOfMirra.Users.get_id(username) |> Gateway.Utils.format_response(conn)
  end

  def get_user(conn, %{"user_id" => user_id}) do
    ChampionsOfMirra.Users.get_user(user_id) |> Gateway.Utils.format_response(conn)
  end
end
