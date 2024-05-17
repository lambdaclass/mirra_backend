defmodule Gateway.Controllers.UserController do
  @moduledoc """
  Controller for User modifications.
  """
  use Gateway, :controller
  alias GameBackend.Users

  action_fallback Gateway.Controllers.FallbackController

  def update(conn, params) do
    with {:ok, user} <- Users.get_user(params["user_id"]),
         {:ok, user} <- Users.update_user(user, params) do
      send_resp(conn, 200, Jason.encode!(user.id))
    end
  end
end
