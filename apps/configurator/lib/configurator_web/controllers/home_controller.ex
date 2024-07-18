defmodule ConfiguratorWeb.HomeController do
  use ConfiguratorWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
