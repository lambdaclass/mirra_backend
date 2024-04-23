defmodule Gateway.Controllers.UserController do
  @moduledoc """
  false
  """
  use Gateway, :controller

  def get_email(conn, %{"user_id" => user_id}) do
    google_user = GameBackend.Users.get_google_user(user_id)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(google_user.email))
  end
end
