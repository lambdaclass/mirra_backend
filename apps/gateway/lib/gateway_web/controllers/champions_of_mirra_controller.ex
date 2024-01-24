defmodule GatewayWeb.ChampionsOfMirraController do
  use GatewayWeb, :controller

  #############
  ## BATTLES ##
  #############

  def get_campaigns(conn, _params) do
    response = ChampionsOfMirra.process_battles(:get_campaigns)
    json(conn, response)
  end

  def get_campaign(conn, %{"campaign_number" => campaign_number}) do
    response = ChampionsOfMirra.process_battles(:get_campaign, campaign_number)
    json(conn, response)
  end

  def get_level(conn, %{"level_id" => level_id}) do
    response = ChampionsOfMirra.process_battles(:get_level, level_id)
    json(conn, response)
  end

  ###########
  ## USERS ##
  ###########

  def create_user(conn, %{"username" => username}) do
    response = ChampionsOfMirra.process_users(:create_user, username)
    json(conn, response)
  end

  def get_user(conn, %{"user_id" => user_id}) do
    response = ChampionsOfMirra.process_users(:get_user, user_id)
    json(conn, response)
  end

  # def battle(conn, %{"user_1" => user_1, "user_2" => user_2}) do
  #   response = ChampionsOfMirra.process_battles(:battle, user_1, user_2)
  #   json(conn, response)
  # end
end
