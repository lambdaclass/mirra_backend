defmodule Gateway.Controllers.AuthController do
  @moduledoc """
  Controller for users authentication.
  """
  use Gateway, :controller
  alias Gateway.Auth.TokenManager
  alias Gateway.Auth.GoogleTokenManager
  alias GameBackend.Users

  def validate_token(conn, %{"provider" => "google", "token_id" => token_id, "client_id" => client_id}) do
    case GoogleTokenManager.verify_and_validate(token_id) do
      {:ok, claims} ->
        {:ok, google_user} = Users.find_or_create_google_user_by_email(claims["email"])
        gateway_jwt = TokenManager.generate_user_token(google_user.user, client_id)
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

  def refresh_token(conn, %{"gateway_jwt" => gateway_jwt, "client_id" => client_id}) do
    with {:ok, claims} <- TokenManager.verify(gateway_jwt),
         hashed_client_id = :crypto.hash(:sha256, client_id),
         {:ok, ^hashed_client_id} <- Base.url_decode64(claims["dev"]),
         {:ok, user} <- Users.get_user(claims["sub"]) do
      new_gateway_jwt = TokenManager.generate_user_token(user, client_id)
      send_resp(conn, 200, Jason.encode!(%{gateway_jwt: new_gateway_jwt, user_id: user.id}))
    else
      _ ->
        send_resp(conn, 400, Jason.encode!(%{error: "bad_request"}))
    end
  end

  def generate_bot_token(conn, %{"bot_secret" => bot_secret}) do
    token = TokenManager.generate_bot_token(bot_secret)
    send_resp(conn, 200, Jason.encode!(%{token: token}))
  end
end
