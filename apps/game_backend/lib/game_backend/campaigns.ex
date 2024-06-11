defmodule GameBackend.Campaigns do
  @moduledoc """
  Operations with Campaigns and Levels.
  """

  import Ecto.Query

  alias Ecto.Multi
  alias GameBackend.Repo
  alias GameBackend.Campaigns.{Campaign, SuperCampaignProgress, Level, SuperCampaign}

  @doc """
  Gets all campaigns, and sorted ascendingly by campaign number.
  """
  def get_campaigns() do
    campaigns =
      Repo.all(
        from(c in Campaign,
          preload: [:super_campaign, levels: ^level_preload_query()],
          order_by: [asc: c.campaign_number]
        )
      )

    if Enum.empty?(campaigns), do: {:error, :no_campaigns}, else: {:ok, campaigns}
  end

  @doc """
  Get a campaign by id.
  """
  def get_campaign(campaign_id) do
    case Repo.one(
           from(c in Campaign, where: c.id == ^campaign_id, preload: [:super_campaign, levels: ^level_preload_query()])
         ) do
      nil -> {:error, :not_found}
      campaign -> {:ok, Map.put(campaign, :levels, Enum.sort_by(campaign.levels, & &1.level_number))}
    end
  end

  defp level_preload_query(),
    do:
      from(l in Level,
        order_by: [asc: l.level_number],
        preload: [
          currency_rewards: :currency,
          units: [:items, :character],
          attempt_cost: :currency,
          item_rewards: :item_template,
          unit_rewards: :character
        ]
      )

  @doc """
  Inserts a level.
  """
  def insert_level(attrs) do
    %Level{}
    |> Level.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a level.
  """
  def update_level(level, attrs) do
    level
    |> Level.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Inserts all Campaigns into the database.
  If another one already exists with the same number and campaign_id, it updates it instead.
  """
  def upsert_levels(attrs_list) do
    Enum.reduce(attrs_list, Multi.new(), fn attrs, multi ->
      # Cannot use Multi.insert because of the embeds_many
      Multi.run(multi, {attrs.campaign_id, attrs.level_number}, fn _, _ ->
        upsert_level(attrs)
      end)
    end)
    |> Repo.transaction()
  end

  defp upsert_level(attrs) do
    case Repo.one(
           from(l in Level,
             where: l.campaign_id == ^attrs.campaign_id and l.level_number == ^attrs.level_number,
             preload: [:units, :currency_rewards, :item_rewards, :unit_rewards, attempt_cost: :currency]
           )
         ) do
      nil -> insert_level(attrs)
      level -> update_level(level, attrs)
    end
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
  def insert_super_campaign_progress(attrs, opts \\ []) do
    %SuperCampaignProgress{}
    |> SuperCampaignProgress.changeset(attrs)
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
    level =
      Repo.get(Level, level_id)
      |> Repo.preload([
        :currency_rewards,
        campaign: :super_campaign,
        attempt_cost: :currency,
        item_rewards: :item_template,
        unit_rewards: :character,
        units: [
          :items,
          character: [basic_skill: [mechanics: :apply_effects_to], ultimate_skill: [mechanics: :apply_effects_to]]
        ]
      ])

    if level, do: {:ok, level}, else: {:error, :not_found}
  end

  @doc """
  Get all of a User's SuperCampaignProgresses.
  """
  def get_user_super_campaign_progresses(user_id),
    do: Repo.all(from(cp in SuperCampaignProgress, where: cp.user_id == ^user_id, preload: [:level, :super_campaign]))

  @doc """
  Get a super campaign by id.
  """
  def get_super_campaign(super_campaign_id) do
    Repo.get(SuperCampaign, super_campaign_id)
  end

  @doc """
  Get a super campaign by name and game_id.
  """
  def get_super_campaign_by_name_and_game(name, game_id) do
    Repo.get_by(SuperCampaign, name: name, game_id: game_id)
    |> Repo.preload(:campaigns)
  end

  @doc """
  Get a campaign progress by user id and campaign id.
  Returns `{:error, :not_found}` if no progress is found.
  """
  def get_super_campaign_progress(user_id, super_campaign_id) do
    super_campaign_progress =
      Repo.one(
        from(cp in SuperCampaignProgress,
          where: cp.user_id == ^user_id and cp.super_campaign_id == ^super_campaign_id,
          preload: [
            level: [:campaign, :item_rewards, :unit_rewards, currency_rewards: :currency]
          ]
        )
      )

    if super_campaign_progress, do: {:ok, super_campaign_progress}, else: {:error, :not_found}
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

    next_level = Repo.get_by(Level, campaign_id: campaign.id, level_number: level.level_number + 1)

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
