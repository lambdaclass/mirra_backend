defmodule Gateway.Controllers.AuthController do
  @moduledoc """
  Controller for users authentication.
  """
  use Gateway, :controller
  alias Gateway.Auth.TokenManager
  alias Gateway.Auth.GoogleTokenManager
  alias GameBackend.Users

  action_fallback Gateway.Controllers.FallbackController

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
    curse_id = GameBackend.Utils.get_game_id(:curse_of_mirra)

    with {:ok, claims} <- TokenManager.verify(gateway_jwt),
         hashed_client_id = :crypto.hash(:sha256, client_id),
         {:ok, ^hashed_client_id} <- Base.url_decode64(claims["dev"]),
         {:ok, _} <- Users.maybe_generate_daily_quests_for_curse_user(claims["sub"]),
         {:ok, user} <- Users.get_user_by_id_and_game_id(claims["sub"], curse_id) do
      # random_character = Enum.random(user.units).character
      random_character = Enum.find(user.units, fn unit -> unit.character.name == "h4ck" end).character
      default_skin = Enum.find(user.user_skins, fn skin -> skin.character_id == random_character.id and skin.is_default end)
      new_gateway_jwt = TokenManager.generate_user_token(user, client_id)
      send_resp(conn, 200, Jason.encode!(%{user_id: user.id, gateway_jwt: new_gateway_jwt, character: %{character_name: random_character.name, skin_id: default_skin}}))
    end
  end
end
