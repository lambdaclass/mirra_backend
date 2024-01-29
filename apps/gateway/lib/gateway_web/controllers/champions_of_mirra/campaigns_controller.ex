defmodule GatewayWeb.ChampionsOfMirra.CampaignsController do
  @moduledoc """
  Controller for Champions Of Mirra requests involving campaigns.

  No logic should be handled here. All logic should be handled through the ChampionsOfMirra app.
  """

  use GatewayWeb, :controller

  def get_campaigns(conn, _params) do
    ChampionsOfMirra.Campaigns.get_campaigns() |> GatewayWeb.Utils.format_response(conn)
  end

  def get_campaign(conn, %{"campaign_number" => campaign_number}) do
    ChampionsOfMirra.Campaigns.get_campaign(campaign_number) |> GatewayWeb.Utils.format_response(conn)
  end

  def get_level(conn, %{"level_id" => level_id}) do
    ChampionsOfMirra.Campaigns.get_level(level_id) |> GatewayWeb.Utils.format_response(conn)
  end

  def fight_level(conn, %{"user_id" => user_id, "level_id" => level_id}) do
    ChampionsOfMirra.Campaigns.fight_level(user_id, level_id)
    |> GatewayWeb.Utils.format_response(conn)
  end
end
