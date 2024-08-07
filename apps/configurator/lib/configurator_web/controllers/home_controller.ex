defmodule ConfiguratorWeb.HomeController do
  use ConfiguratorWeb, :controller

  def home(conn, _params) do
    current_user = get_session(conn, :current_user)
    render(conn, :home, current_user: current_user)
  end
end
