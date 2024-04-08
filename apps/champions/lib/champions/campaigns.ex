defmodule Champions.Campaigns do
  @moduledoc """
  Campaigns logic for Champions of Mirra.
  """

  alias Champions.Users
  alias GameBackend.Campaigns
  alias GameBackend.Campaigns.CampaignProgress
  alias GameBackend.Items.Item
  alias GameBackend.Repo
  alias GameBackend.Rewards
  alias GameBackend.Transaction
  alias GameBackend.Units.Unit
  alias GameBackend.Users.Currencies
  alias Ecto.Multi

  @doc """
  Gets all campaigns, and sorted ascendingly by campaign number.
  """
  def get_campaigns() do
    Campaigns.get_campaigns()
  end

  @doc """
  Get a campaign by id.
  """
  def get_campaign(campaign_id) do
    Campaigns.get_campaign(campaign_id)
  end

  @doc """
  Inserts a level.
  """
  def insert_level(attrs) do
    Campaigns.insert_level(attrs)
  end

  @doc """
  Get a level by id.
  """
  def get_level(level_id), do: Campaigns.get_level(level_id)

  @doc """
  Get all of user's SuperCampaignProgress.
  """
  def get_user_super_campaign_progresses(user_id), do: Campaigns.get_user_super_campaign_progresses(user_id)
end
