defmodule GameBackend.Campaigns do
  @moduledoc """
  Operations with Campaigns and Levels.
  """

  import Ecto.Query
  alias GameBackend.Repo
  alias GameBackend.Campaigns.Campaign
  alias GameBackend.Campaigns.CampaignProgression
  alias GameBackend.Campaigns.Level
  alias GameBackend.Campaigns.Quest

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
    # campaign =
    #   Repo.all(from(l in Level, where: l.campaign == ^campaign_number))
    #   |> Repo.preload(units: [:character, :items])

    # case campaign do
    #   [] -> {:error, :not_found}
    #   campaign -> campaign
    # end
    campaign =
      Repo.get(Campaign, campaign_id)
      |> Repo.preload(levels: [:units])

    if campaign, do: campaign, else: {:error, :not_found}
  end

  @doc """
  Inserts a level.
  """
  def insert_level(attrs) do
    %Level{}
    |> Level.changeset(attrs)
    |> Repo.insert()
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
    |> IO.inspect()
    |> Repo.insert(opts)
  end

  @doc """
  Inserts a quest.
  """
  def insert_quest(attrs, opts \\ []) do
    %Quest{}
    |> Quest.changeset(attrs)
    |> Repo.insert(opts)
  end

  @doc """
  Get a level by id.
  """
  def get_level(level_id) do
    Repo.get(Level, level_id) |> Repo.preload(units: :items, units: :character)
  end

  def get_campaign_progression(user_id, campaign_id) do
    Repo.get_by(GameBackend.Campaigns.CampaignProgression,
      user_id: user_id,
      campaign_id: campaign_id
    )
  end

  def get_next_level(campaign, level) do
    next_level =
      Repo.get_by(Level, campaign_id: campaign.id, level_number: level.level_number + 1)

    if next_level do
      {campaign.id, next_level.id}
    else
      next_campaign =
        Repo.get(Campaign,
          quest_id: campaign.quest_id,
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
