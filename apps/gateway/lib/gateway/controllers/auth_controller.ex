defmodule Gateway.Controllers.AuthController do
  @moduledoc """
  Controller for users authentication.
  """
  use Gateway, :controller
  alias Gateway.Auth.Guardian
  alias Gateway.Auth.GoogleTokenManager
  alias GameBackend.Users

  def validate_token(conn, %{"provider" => "google", "token_id" => token_id}) do
    case GoogleTokenManager.verify_and_validate(token_id) do
      {:ok, claims} ->
        {:ok, google_user} = Users.find_or_create_google_user_by_email(claims["email"])
        user_response = %{id: google_user.user.id, email: google_user.email}
        {:ok, gateway_jwt, _} = Guardian.encode_and_sign(user_response)
        response = %{claims: claims, user: user_response, gateway_jwt: gateway_jwt}
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
