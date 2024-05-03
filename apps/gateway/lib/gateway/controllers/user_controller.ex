defmodule Gateway.Controllers.UserController do
  @moduledoc """
  Controller for User modifications.
  """
  use Gateway, :controller
  alias GameBackend.Users

  def update(conn, params) do
    conn = put_resp_content_type(conn, "application/json")

    with {:ok, user} <- Users.get_user(params["user_id"]),
         {:ok, user} <- Users.update_user(user, params) do
      send_resp(conn, 200, Jason.encode!(user.id))
    else
      {:error, :not_found} -> send_resp(conn, 404, Jason.encode!(%{"error" => "not found"}))
      {:error, _changeset} -> send_resp(conn, 400, Jason.encode!(%{"error" => "failed to update"}))
    end
  end
end
