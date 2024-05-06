defmodule GameClientWeb.AuthController do
  use GameClientWeb, :controller
  plug Ueberauth

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    token = auth.extra.raw_info.token.other_params["id_token"]
    gateway_url = Application.get_env(:game_client, :gateway_url)

    response =
      Finch.build(:get, "#{gateway_url}/auth/google/token/#{token}", [{"content-type", "application/json"}])
      |> Finch.request(GameClient.Finch)

    case response do
      {:ok, %{status: 200, body: body}} ->
        body = Jason.decode!(body)

        conn
        |> put_flash(:info, "Logged in successfully.")
        |> put_session(:user_id, get_in(body, ["user", "id"]))
        |> redirect(to: ~p"/")

      {:ok, %{status: 400}} ->
        conn
        |> put_flash(:error, "Error loging in")
        |> redirect(to: ~p"/")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "An error occurred")
        |> redirect(to: ~p"/")
    end
  end
end