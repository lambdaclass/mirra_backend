defmodule Gateway.Controllers.AuthController do
  @moduledoc """
  Controller for users authentication.
  """
  use Gateway, :controller
  plug Ueberauth
  alias Ueberauth.Strategy.Helpers

  def request(conn, _params) do
    render(conn, :request, callback_url: Helpers.callback_url(conn))
  end

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Failed to authenticate.")
    |> redirect(to: "/auth/google")
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    case GameBackend.Users.find_or_create_google_user_by_email(auth.info.email) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Successfully authenticated.")
        |> put_session(:current_user, user)
        |> configure_session(renew: true)
        |> redirect(to: "/")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Something went wrong. Try again.")
        |> redirect(to: "/auth/google")
    end
  end
end
