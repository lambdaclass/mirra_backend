defmodule GameBackendWeb.PageController do
  use GameBackendWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
