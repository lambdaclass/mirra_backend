defmodule GameBackend.Users do
  @moduledoc """
  The Users module defines utilites for interacting with Users, that are common across all games. Also defines the data structures themselves. Operations that can be done to a User are:
  - Create

  For now, users consist of only a username. No authentication of any sort has been implemented.
  """

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias GameBackend.Campaigns.CampaignProgression
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

  Returns {:error, :not_found} if no user is found.

  ## Examples

      iex> get_user("51646f3a-d9e9-4ce6-8341-c90b8cad3bdf")
      %User{}

      iex> get_user("9483ae81-f3e8-4050-acea-13940d47d8ed")
      nil
  """
  def get_user(id) do
    user = Repo.get(User, id) |> preload()
    if user, do: {:ok, user}, else: {:error, :not_found}
  end

  @doc """
  Gets a user by their username.

  Returns {:error, :not_found} if no user is found.

  ## Examples

      iex> get_user_by_username("some_user")
      {:ok, %User{}}

      iex> get_user_by_username("non_existing_user")
      {:error, :not_found}
  """
  def get_user_by_username(username) do
    user = Repo.get_by(User, username: username) |> preload()
    if user, do: {:ok, user}, else: {:error, :not_found}
  end

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
    with {:campaign_data, {:ok, campaign_progression}} <-
           {:campaign_data, retrieve_campaign_progression_data(user_id, campaign_id)},
         {:next_level, {next_campaign_id, next_level_id}} =
           {:next_level, Campaigns.get_next_level(campaign_progression.level)} do
      level = campaign_progression.level

      Multi.new()
      |> Multi.run(:update_campaign_progression, fn _, _ ->
        if next_level_id == level.id,
          do: {:ok, nil},
          else: update_campaign_progression(campaign_progression, next_campaign_id, next_level_id)
      end)
      |> Repo.transaction()
    else
      {:campaign_data, _transaction_error} -> {:error, :campaign_data_error}
      {:next_level, _transaction_error} -> {:campaign_progression_error}
    end
  end

  def reset_afk_rewards_claim(user_id) do
    {:ok, user} = get_user(user_id)

    user
    |> User.changeset(%{last_afk_reward_claim: DateTime.utc_now()})
    |> Repo.update()
  end

  defp preload(user),
    do:
      Repo.preload(user,
        items: :template,
        units: [:character, :items],
        currencies: :currency
      )

  defp retrieve_campaign_progression_data(user_id, campaign_id) do
    progression =
      Repo.get_by(CampaignProgression, user_id: user_id, campaign_id: campaign_id)
      |> Repo.preload(level: :campaign)

    case progression do
      nil -> {:error, :not_found}
      campaign_progression -> {:ok, campaign_progression}
    end
  end

  defp update_campaign_progression(campaign_progression, next_campaign_id, next_level_id) do
    campaign_progression
    |> CampaignProgression.advance_level_changeset(%{
      campaign_id: next_campaign_id,
      level_id: next_level_id
    })
    |> Repo.update()
  end
end
