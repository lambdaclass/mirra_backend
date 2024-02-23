defmodule GameBackend.Campaigns do
  @moduledoc """
  Operations with Campaigns and Levels.
  """

  import Ecto.Query
  alias GameBackend.Repo
  alias GameBackend.Campaigns.Campaign
  alias GameBackend.Campaigns.CampaignProgression
  alias GameBackend.Campaigns.Level
  alias GameBackend.Campaigns.SuperCampaign

  @doc """
  Gets all levels, grouped by campaign and sorted ascendingly.
  """
  def get_campaigns() do
    campaigns =
      Repo.all(from(c in Campaign))
      |> Repo.preload(levels: [:currency_rewards, :item_rewards, :unit_rewards, units: :items])

    if Enum.empty?(campaigns), do: {:error, :no_campaigns}, else: campaigns
  end

  def get_campaign(campaign_id) do
    campaign =
      Repo.get(Campaign, campaign_id)
      |> Repo.preload(levels: [:units])

    if campaign, do: {:ok, campaign}, else: {:error, :not_found}
  end

  @doc """
  Inserts a campaign.
  """
  def insert_campaign(attrs, opts \\ []) do
    %Campaign{}
    |> Campaign.changeset(attrs)
    |> Repo.insert(opts)
  end

  @doc """
  Inserts a campaign progression.
  """
  def insert_campaign_progression(attrs, opts \\ []) do
    %CampaignProgression{}
    |> CampaignProgression.changeset(attrs)
    |> Repo.insert(opts)
  end

  @doc """
  Inserts a super campaign.
  """
  def insert_super_campaign(attrs, opts \\ []) do
    %SuperCampaign{}
    |> SuperCampaign.changeset(attrs)
    |> Repo.insert(opts)
  end

  @doc """
  Get a level by id.
  Returns `{:error, :not_found}` if no level is found.
  """
  def get_level(level_id) do
    level = Repo.get(Level, level_id) |> Repo.preload(units: :items, units: :character)
    if level, do: {:ok, level}, else: {:error, :not_found}
  end

  @doc """
  Get a campaign progression by user id and campaign id.
  Returns `{:error, :not_found}` if no progression is found.
  """
  def get_campaign_progression(user_id, campaign_id) do
    campaign_progression =
      Repo.get_by(GameBackend.Campaigns.CampaignProgression,
        user_id: user_id,
        campaign_id: campaign_id
      )

    if campaign_progression, do: {:ok, campaign_progression}, else: {:error, :not_found}
  end

  @doc """
  Returns what the next level is for a user with its campaign in a tuple.

  Usually it is the level in the same campaign with the next `level_number`.
  If it doesn't exist it means the campaign is over and we go find the next one by
  `campaign_number`. If it doesn't exist, we have cleared the SuperCampaign and we return
  the same given campaign and level instead.
  """
  def get_next_level(campaign, level) do
    next_level =
      Repo.get_by(Level, campaign_id: campaign.id, level_number: level.level_number + 1)

    if next_level do
      {campaign.id, next_level.id}
    else
      next_campaign =
        Repo.get_by(Campaign,
          super_campaign_id: campaign.super_campaign_id,
          campaign_number: campaign.campaign_number + 1
        )

      if next_campaign do
        first_level = Repo.get_by(Level, campaign_id: next_campaign.id, level_number: 1)
        {next_campaign.id, first_level.id}
      else
        {campaign.id, level.id}
      end
    end
  end
end
