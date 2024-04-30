defmodule Gateway.Controllers.AuthController do
  @moduledoc """
  Controller for users authentication.
  """
  use Gateway, :controller
  alias Gateway.Auth.GoogleTokenManager
  alias GameBackend.Users

  def validate_token(conn, %{"provider" => "google", "token_id" => token_id}) do
    case GoogleTokenManager.verify_and_validate(token_id) do
      {:ok, response} ->
        Users.find_or_create_google_user_by_email(response["email"])
        send_resp(conn, 200, Jason.encode!(response))

      {:error, error} ->
        send_resp(conn, 400, Jason.encode!(Map.new(error)))
    end
  end
end
