defmodule Gateway.Champions.UsersController do
  @moduledoc """
  Controller for Champions Of Mirra requests involving users.

  No logic should be handled here. All logic should be handled through the Champions app.
  """

  use Gateway, :controller

  def create_user(conn, %{"username" => username}) do
    Champions.Users.register(username) |> Gateway.Utils.format_response(conn)
  end

  def get_user_by_username(conn, %{"username" => username}) do
    Champions.Users.get_user_by_username(username) |> Gateway.Utils.format_response(conn)
  end

  def get_user(conn, %{"user_id" => user_id}) do
    Champions.Users.get_user(user_id) |> Gateway.Utils.format_response(conn)
  end
end
