defmodule Champions.Campaigns do
  @moduledoc """
  Campaigns logic for Champions of Mirra.
  """

  alias GameBackend.Campaigns
  alias GameBackend.Campaigns.SuperCampaignProgress
  alias GameBackend.Items.Item
  alias GameBackend.Repo
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

  @doc """
  Increments a user's level and apply the level's rewards.
  If it was the last level in the campaign, increments the campaign number and sets the level number to 1.
  """
  def advance_level(user_id, super_campaign_id) do
    with {:super_campaign_progress, {:ok, super_campaign_progress}} <-
           {:super_campaign_progress, Campaigns.get_super_campaign_progress(user_id, super_campaign_id)},
         {:next_level, {next_campaign_id, next_level_id}} <-
           {:next_level, Campaigns.get_next_level(super_campaign_progress.level)} do
      level = super_campaign_progress.level

      # TODO: Implement experience rewards [CHoM-#216]
      Multi.new()
      |> apply_currency_rewards(user_id, level.currency_rewards)
      |> Multi.insert_all(:item_rewards, Item, fn _ ->
        build_item_rewards_params(user_id, level.item_rewards)
      end)
      |> Multi.insert_all(:unit_rewards, Unit, fn _ ->
        build_unit_rewards_params(user_id, level.unit_rewards)
      end)
      |> Multi.run(:update_campaign_progress, fn _, _ ->
        if next_level_id == level.id,
          do: {:ok, nil},
          else: update_super_campaign_progress(super_campaign_progress, next_campaign_id, next_level_id)
      end)
      |> Repo.transaction()
    else
      {:super_campaign_progress, _transaction_error} -> {:error, :super_campaign_progress_not_found}
      {:next_level, _transaction_error} -> {:super_campaign_progress_error}
    end
  end

  defp update_super_campaign_progress(super_campaign_progress, next_campaign_id, next_level_id) do
    super_campaign_progress
    |> SuperCampaignProgress.advance_level_changeset(%{
      campaign_id: next_campaign_id,
      level_id: next_level_id
    })
    |> Repo.update()
  end

  defp build_item_rewards_params(user_id, item_rewards) do
    Enum.map(item_rewards, fn item_reward ->
      Enum.map(1..item_reward.amount, fn _ ->
        %{
          user_id: user_id,
          template_id: item_reward.item_template_id,
          level: 1,
          inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
          updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        }
      end)
    end)
    |> List.flatten()
  end

  defp build_unit_rewards_params(user_id, unit_rewards) do
    Enum.map(unit_rewards, fn unit_reward ->
      Enum.map(1..unit_reward.amount, fn _ ->
        %{
          user_id: user_id,
          character_id: unit_reward.character_id,
          level: 1,
          tier: 1,
          rank: unit_reward.rank,
          selected: false,
          inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
          updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        }
      end)
    end)
    |> List.flatten()
  end

  defp apply_currency_rewards(multi, user_id, currency_rewards) do
    Enum.reduce(currency_rewards, multi, fn currency_reward, multi ->
      Multi.run(multi, {:add_currency, currency_reward.currency_id}, fn _, _ ->
        Currencies.add_currency(user_id, currency_reward.currency_id, currency_reward.amount)
      end)
    end)
  end
end
