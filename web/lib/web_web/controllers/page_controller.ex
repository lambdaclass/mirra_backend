defmodule WebWeb.PageController do
  use WebWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
