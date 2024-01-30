defmodule Gateway.Champions.CampaignsController do
  @moduledoc """
  Controller for Champions Of Mirra requests involving campaigns.

  No logic should be handled here. All logic should be handled through the Champions app.
  """

  use Gateway, :controller

  def get_campaigns(conn, _params) do
    Champions.Campaigns.get_campaigns() |> Gateway.Utils.format_response(conn)
  end

  def get_campaign(conn, %{"campaign_number" => campaign_number}) do
    Champions.Campaigns.get_campaign(campaign_number)
    |> Gateway.Utils.format_response(conn)
  end

  def get_level(conn, %{"level_id" => level_id}) do
    Champions.Campaigns.get_level(level_id) |> Gateway.Utils.format_response(conn)
  end

  def fight_level(conn, %{"user_id" => user_id, "level_id" => level_id}) do
    Champions.Battle.fight_level(user_id, level_id)
    |> Gateway.Utils.format_response(conn)
  end
end
