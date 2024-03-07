defmodule GameBackend.Campaigns do
  @moduledoc """
  Operations with Campaigns and Levels.
  """

  import Ecto.Query
  alias GameBackend.Repo
  alias GameBackend.Campaigns.{Campaign, CampaignProgress, Level, SuperCampaign}

  @doc """
  Gets all levels, grouped by campaign and sorted ascendingly.
  """
  def get_campaigns() do
    campaigns =
      Repo.all(from(c in Campaign))
      |> Repo.preload(levels: [:currency_rewards, units: :items])

    if Enum.empty?(campaigns),
      do: {:error, :no_campaigns},
      else: Enum.sort_by(campaigns, & &1.campaign_number)
  end

  @doc """
  Get a campaign by id.
  """
  def get_campaign(campaign_id) do
    case Repo.get(Campaign, campaign_id) |> Repo.preload(levels: [:units]) do
      nil ->
        {:error, :not_found}

      campaign ->
        {:ok, Map.put(campaign, :levels, Enum.sort_by(campaign.levels, & &1.level_number))}
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
  Inserts a campaign progress.
  """
  def insert_campaign_progress(attrs, opts \\ []) do
    %CampaignProgress{}
    |> CampaignProgress.changeset(attrs)
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
  Get a campaign progress by user id and campaign id.
  Returns `{:error, :not_found}` if no progress is found.
  """
  def get_campaign_progress(user_id, campaign_id) do
    campaign_progress =
      Repo.one(
        from(cp in CampaignProgress,
          where: cp.user_id == ^user_id and cp.campaign_id == ^campaign_id,
          preload: [level: :campaign]
        )
      )

    if campaign_progress, do: {:ok, campaign_progress}, else: {:error, :not_found}
  end

  @doc """
  Returns what the next level is for a user with its campaign in a tuple.

  Usually it is the level in the same campaign with the next `level_number`.
  If it doesn't exist it means the campaign is over and we go find the next one by
  `campaign_number`. If it doesn't exist, we have cleared the SuperCampaign and we return
  the same given campaign and level instead.
  """
  def get_next_level(level) do
    campaign = level.campaign

    next_level =
      Repo.get_by(Level, campaign_id: campaign.id, level_number: level.level_number + 1)

    next_campaign =
      Repo.get_by(Campaign,
        super_campaign_id: campaign.super_campaign_id,
        campaign_number: campaign.campaign_number + 1
      )

    cond do
      not is_nil(next_level) ->
        {campaign.id, next_level.id}

      not is_nil(next_campaign) ->
        first_level = Repo.get_by(Level, campaign_id: next_campaign.id, level_number: 1)
        {next_campaign.id, first_level.id}

      true ->
        {campaign.id, level.id}
    end
  end
end
