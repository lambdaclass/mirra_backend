defmodule GameBackend.Users do
  @moduledoc """
  The Users module defines utilites for interacting with Users, that are common across all games. Also defines the data structures themselves. Operations that can be done to a User are:
  - Create

  For now, users consist of only a username. No authentication of any sort has been implemented.
  """

  import Ecto.Query, warn: false

  alias GameBackend.Items
  alias GameBackend.Users.Currencies
  alias GameBackend.Users.Currencies.UserCurrency
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

  @doc """
  Increments a user's level and apply the level's rewards.
  If it was the last level in the campaign, increments the campaign number and sets the level number to 1.
  """
  def advance_level(user_id, campaign_id) do
    {:ok, {campaign_progression, level, campaign}} =
      retrieve_campaign_data(user_id, campaign_id)

    {next_campaign_id, next_level_id} = Campaigns.get_next_level(campaign, level)

    {:ok, updated_campaign_progression} =
      update_campaign_progression(campaign_progression, next_campaign_id, next_level_id)

    {:ok, updated_user} = update_user(user_id, level)
    IO.inspect(updated_user, label: "updated_user")

    {updated_campaign_progression, updated_user}
  end

  defp preload(user),
    do: Repo.preload(user, items: :template, units: [:character, :items], currencies: :currency)

  defp retrieve_campaign_data(user_id, campaign_id) do
    Repo.transaction(fn ->
      campaign_progression =
        Repo.get_by(CampaignProgression, user_id: user_id, campaign_id: campaign_id)

      level = Repo.get(Level, campaign_progression.level_id) |> Repo.preload(:currency_rewards)
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
      # user = Repo.get!(User, user_id) |> preload()

      # user
      # |> User.reward_changeset(%{
      #   # currencies: convert_currency_rewards(level.currency_rewards),
      #   items: level.item_rewards,
      #   units: level.unit_rewards
      # })
      # |> Repo.update()
      level.currency_rewards
      |> Enum.each(fn currency_reward ->
        Currencies.add_currency(user_id, currency_reward.currency_id, currency_reward.amount)
      end)

      Repo.get!(User, user_id) |> preload()
    end)
  end
end
