defmodule Gateway.Controllers.AuthController do
  @moduledoc """
  Controller for users authentication.
  """
  use Gateway, :controller
  alias Gateway.Auth.GatewayTokenManager
  alias Gateway.Auth.GoogleTokenManager
  alias GameBackend.Users

  def validate_token(conn, %{"provider" => "google", "token_id" => token_id}) do
    case GoogleTokenManager.verify_and_validate(token_id) do
      {:ok, claims} ->
        {:ok, google_user} = Users.find_or_create_google_user_by_email(claims["email"])
        gateway_jwt = GatewayTokenManager.generate_user_token(google_user.user)
        user_response = %{id: google_user.user.id, email: google_user.email}
        response = %{claims: claims, user: user_response, gateway_jwt: gateway_jwt}
        send_resp(conn, 200, Jason.encode!(response))

      {:error, error} ->
        send_resp(conn, 400, Jason.encode!(Map.new(error)))
    end
  end

  def public_key(conn, _params) do
    signer = Joken.Signer.parse_config(:default_signer)

    {_, jwk} =
      signer.jwk
      |> JOSE.JWK.to_public()
      |> JOSE.JWK.to_map()

    json(conn, %{jwk: jwk})
  end
end
