defmodule Gateway.Controllers.UserController do
  @moduledoc """
  Controller for User modifications.
  """
  use Gateway, :controller
  alias GameBackend.Users

  def change_username(conn, params) do
    update_user_params(conn, params.user_id, %{"username" => params.username})
  end

  def change_profile_picture(conn, params) do
    update_user_params(conn, params.user_id, %{"profile_picture" => params.profile_picture})
  end

  defp update_user_params(conn, user_id, params) do
    conn = put_resp_content_type(conn, "application/json")

    with {:ok, user} <- Users.get_user(user_id),
         {:ok, user} <- Users.update_user(user, params) do
      send_resp(conn, 200, Jason.encode!(user))
    else
      {:error, :not_found} -> send_resp(conn, 200, Jason.encode!(%{"error" => "not found"}))
      {:error, _changeset} -> send_resp(conn, 200, Jason.encode!(%{"error" => "failed to update"}))
    end
  end
end
