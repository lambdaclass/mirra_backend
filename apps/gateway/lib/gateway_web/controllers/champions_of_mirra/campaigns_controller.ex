defmodule GatewayWeb.ChampionsOfMirra.CampaignsController do
  use GatewayWeb, :controller

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

  def fight_level(conn, %{"user_id" => user_id, "level_id" => level_id}) do
    response = ChampionsOfMirra.process_battles(:fight_level, user_id, level_id)
    json(conn, response)
  end
end
