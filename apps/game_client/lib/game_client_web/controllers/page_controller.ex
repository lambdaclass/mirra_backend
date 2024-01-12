defmodule GameClientWeb.PageController do
  use GameClientWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
