defmodule GatewayWeb.ChampionsOfMirraController do
  use GatewayWeb, :controller

  def get_campaigns(conn, _params) do
    response = ChampionsOfMirra.process(:get_campaigns)
    json(conn, response)
  end

  def create_user(conn, %{"username" => username}) do
    response = ChampionsOfMirra.process(:create_user, username)
    json(conn, response)
  end
end
