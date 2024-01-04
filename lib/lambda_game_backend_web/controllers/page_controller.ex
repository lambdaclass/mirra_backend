defmodule LambdaGameBackendWeb.PageController do
  use LambdaGameBackendWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
