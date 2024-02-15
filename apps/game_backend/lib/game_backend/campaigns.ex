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
      Repo.all(from(l in Level))
      |> Repo.preload(units: [:character, :items])
      |> Enum.sort(fn l1, l2 -> l1.level_number < l2.level_number end)
      |> Enum.group_by(fn l -> l.campaign end)
      |> Map.values()

    if Enum.empty?(campaigns), do: {:error, :no_campaigns}, else: campaigns
  end

  def get_campaign(campaign_number) do
    campaign =
      Repo.all(from(l in Level, where: l.campaign == ^campaign_number))
      |> Repo.preload(units: [:character, :items])

    case campaign do
      [] -> {:error, :not_found}
      campaign -> campaign
    end
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
    Repo.get_by(GameBackend.Campaigns.CampaignsProgression,
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
