defmodule Gateway.Controllers.AuthController do
  @moduledoc """
  Controller for users authentication.
  """
  use Gateway, :controller
  alias Gateway.Auth.TokenManager
  alias Gateway.Auth.GoogleTokenManager
  alias GameBackend.Users
  alias GameBackend.Units

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
         {:ok, user} <- Users.get_user_by_id_and_game_id(claims["sub"], curse_id),
         unit <- Units.get_selected_unit(user.id),
         unit_skin <- Enum.find(unit.skins, fn unit_skin -> unit_skin.selected end) do
      new_gateway_jwt = TokenManager.generate_user_token(user, client_id)

      user.user_quests |> IO.inspect(label: :aver_quests)

      send_resp(
        conn,
        200,
        Jason.encode!(%{
          gateway_jwt: new_gateway_jwt,
          user_id: user.id,
          character_name: unit.character.name,
          skin_name: unit_skin.skin.name
        })
      )
    end
  end
end
