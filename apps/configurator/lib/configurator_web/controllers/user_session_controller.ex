defmodule ConfiguratorWeb.UserSessionController do
  @moduledoc false
  use ConfiguratorWeb, :controller

  alias ConfiguratorWeb.UserAuth

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
