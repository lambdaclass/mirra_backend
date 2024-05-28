defmodule Gateway.Controllers.AuthController do
  @moduledoc """
  Controller for users authentication.
  """
  use Gateway, :controller
  alias Gateway.Auth.GoogleTokenManager
  alias GameBackend.Users

  def validate_token(conn, %{"provider" => "google", "token_id" => token_id}) do
    case GoogleTokenManager.verify_and_validate(token_id) do
      {:ok, claims} ->
        {:ok, user} = Users.find_or_create_google_user_by_email(claims["email"])
        {user, _} = Map.split(user, [:id, :email])
        response = %{claims: claims, user: user}
        send_resp(conn, 200, Jason.encode!(response))

      {:error, error} ->
        send_resp(conn, 400, Jason.encode!(Map.new(error)))
    end
  end

  def public_key(conn, _params) do
    {_, jwk} =
      Application.get_env(:gateway, Gateway.Auth.Guardian)[:jwt_private_key]
      |> JOSE.JWK.from_openssh_key()
      |> JOSE.JWK.to_public()
      |> JOSE.JWK.to_map()

    json(conn, %{jwk: jwk})
  end
end
