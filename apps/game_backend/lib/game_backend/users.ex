defmodule GameBackend.Users do
  @moduledoc """
  The Users module defines utilites for interacting with Users, that are common across all games. Also defines the data structures themselves. Operations that can be done to a User are:
  - Create

  For now, users consist of only a username. No authentication of any sort has been implemented.
  """

  import Ecto.Query, warn: false

  alias GameBackend.Units
  alias GameBackend.Items
  alias GameBackend.Rewards
  alias GameBackend.Users.Currencies
  alias GameBackend.Campaigns.CampaignProgression
  alias GameBackend.Campaigns.Campaign
  alias GameBackend.Campaigns.Level
  alias GameBackend.Campaigns
  alias GameBackend.Repo
  alias GameBackend.Users.User

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets a single user.

  Returns nil if no user is found.

  ## Examples

      iex> get_user("51646f3a-d9e9-4ce6-8341-c90b8cad3bdf")
      %User{}

      iex> get_user("9483ae81-f3e8-4050-acea-13940d47d8ed")
      nil
  """
  def get_user(id), do: Repo.get(User, id) |> preload()

  @doc """
  Gets a user by their username.

  Returns nil if no user is found.

  ## Examples

      iex> get_user_by_username("some_user")
      %User{}

      iex> get_user_by_username("non_existing_user")
      nil
  """
  def get_user_by_username(username), do: Repo.get_by(User, username: username) |> preload()

  def update_experience(user, params),
    do:
      user
      |> User.experience_changeset(params)
      |> Repo.update()

  @doc """
  Increments a user's level and apply the level's rewards.
  If it was the last level in the campaign, increments the campaign number and sets the level number to 1.
  """
  def advance_level(user_id, campaign_id) do
    {:ok, {campaign_progression, level, campaign}} =
      retrieve_campaign_data(user_id, campaign_id)

    {next_campaign_id, next_level_id} = Campaigns.get_next_level(campaign, level)

    {:ok, _} =
      update_campaign_progression(campaign_progression, next_campaign_id, next_level_id)

    update_user(user_id, level)

    :ok
  end

  def reset_afk_rewards_claim(user_id) do
    user = get_user(user_id)

    user
    |> User.changeset(%{last_afk_reward_claim: DateTime.utc_now()})
    |> Repo.update()
  end

  defp preload(user),
    do:
      Repo.preload(user, [
        :afk_reward_rates,
        items: :template,
        units: [:character, :items],
        currencies: :currency
      ])

  defp retrieve_campaign_data(user_id, campaign_id) do
    Repo.transaction(fn ->
      campaign_progression =
        Repo.get_by(CampaignProgression, user_id: user_id, campaign_id: campaign_id)

      level =
        Repo.get(Level, campaign_progression.level_id)
        |> Repo.preload([
          :currency_rewards,
          :afk_rewards_increments,
          :item_rewards,
          :unit_rewards
        ])

      campaign = Repo.get(Campaign, campaign_id)

      {campaign_progression, level, campaign}
    end)
  end

  defp update_campaign_progression(campaign_progression, next_campaign_id, next_level_id) do
    campaign_progression
    |> CampaignProgression.advance_level_changeset(%{
      campaign_id: next_campaign_id,
      level_id: next_level_id
    })
    |> Repo.update()
  end

  defp update_user(user_id, level) do
    Repo.transaction(fn ->
      apply_currency_rewards(user_id, level.currency_rewards)
      apply_afk_rewards_increments(user_id, level.afk_rewards_increments)
      apply_item_rewards(user_id, level.item_rewards)
      apply_unit_rewards(user_id, level.unit_rewards)
      :ok
    end)
  end

  defp apply_currency_rewards(user_id, currency_rewards) do
    currency_rewards
    |> Enum.each(fn currency_reward ->
      Currencies.add_currency(user_id, currency_reward.currency_id, currency_reward.amount)
    end)
  end

  defp apply_afk_rewards_increments(user_id, afk_rewards_increments) do
    afk_rewards_increments
    |> Enum.each(fn increment ->
      Rewards.increment_afk_reward_rate(user_id, increment.currency_id, increment.amount)
    end)
  end

  defp apply_item_rewards(user_id, item_rewards) do
    item_rewards
    |> Enum.each(fn item_reward ->
      {:ok, item} = Items.get_item(item_reward.item_id)

      Enum.each(1..item_reward.amount, fn _ ->
        Items.insert_item(%{
          user_id: user_id,
          template_id: item.template_id,
          level: item.level
        })
      end)
    end)
  end

  defp apply_unit_rewards(user_id, unit_rewards) do
    unit_rewards
    |> Enum.each(fn unit_reward ->
      unit = Units.get_unit(unit_reward.unit_id)

      Enum.each(1..unit_reward.amount, fn _ ->
        Units.insert_unit(%{
          user_id: user_id,
          character_id: unit.character_id,
          unit_level: unit.level,
          tier: unit.tier,
          selected: false
        })
      end)
    end)
  end
end
