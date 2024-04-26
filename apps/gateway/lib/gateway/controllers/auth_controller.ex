defmodule Gateway.Controllers.AuthController do
  @moduledoc """
  Controller for users authentication.
  """
  use Gateway, :controller
  alias Ueberauth.Strategy.Helpers

  ## You will see this and surely think "WTF?". Trust me, this is a sane approach to what we wanted
  ## The idea here was to have 2 different redirects at the end of the authentication,
  ## one for the browser and another for the unity client. Since we weren't allowed to pass params or anything of the sort
  ## having 2 distinct routes allows us to pattern match and properly choose the correct redirect
  ## So, this double invocation of `plug Ueberauth` is because each one will intercept the calls for that specific base_path
  plug Ueberauth, base_path: "/auth/browser"
  plug Ueberauth, base_path: "/auth/unity"

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
        |> redirect(external: path_to_redirect_url(conn.path_info, user.id))

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Something went wrong. Try again.")
        |> redirect(to: "/auth/google")
    end
  end

  defp path_to_redirect_url(["auth", "browser" | _], user_id), do: "http://localhost:3000/#{user_id}"
  ## TODO: change to proper deeplink
  defp path_to_redirect_url(["auth", "unity" | _], user_id), do: "http://localhost:3000/#{user_id}?unity=true"
end
