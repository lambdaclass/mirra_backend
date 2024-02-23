defmodule GameBackend.Users do
  @moduledoc """
  The Users module defines utilites for interacting with Users, that are common across all games. Also defines the data structures themselves. Operations that can be done to a User are:
  - Create

  For now, users consist of only a username. No authentication of any sort has been implemented.
  """

  import Ecto.Query, warn: false

  alias GameBackend.Units.Unit
  alias GameBackend.Items.Item
  alias Ecto.Multi
  alias GameBackend.Units
  alias GameBackend.Items
  alias GameBackend.Rewards
  alias GameBackend.Users.Currencies
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
      |> Multi.run(:currency_rewards, fn _, _ ->
        apply_currency_rewards(user_id, level.currency_rewards)
      end)
      |> Multi.run(:afk_rewards_increments, fn _, _ ->
        apply_afk_rewards_increments(user_id, level.afk_rewards_increments)
      end)
      |> Multi.insert_all(:item_rewards, Item, fn _ ->
        build_item_rewards_params(user_id, level.item_rewards)
      end)
      |> Multi.insert_all(:unit_rewards, Unit, fn _ ->
        build_unit_rewards_params(user_id, level.unit_rewards)
      end)
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
      Repo.preload(user, [
        :afk_reward_rates,
        items: :template,
        units: [:character, :items],
        currencies: :currency
      ])

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

  defp apply_currency_rewards(user_id, currency_rewards) do
    Enum.map(currency_rewards, fn currency_reward ->
      Currencies.add_currency(user_id, currency_reward.currency_id, currency_reward.amount)
    end)
    |> check_result(:currency_rewards)
  end

  defp apply_afk_rewards_increments(user_id, afk_rewards_increments) do
    Enum.map(afk_rewards_increments, fn increment ->
      Rewards.increment_afk_reward_rate(user_id, increment.currency_id, increment.amount)
    end)
    |> check_result(:afk_rewards_increments)
  end

  defp build_item_rewards_params(user_id, item_rewards) do
    Enum.map(item_rewards, fn item_reward ->
      Items.get_item(item_reward.item_id)
      |> case do
        {:ok, item} ->
          Enum.map(1..item_reward.amount, fn _ ->
            %{
              user_id: user_id,
              template_id: item.template_id,
              level: item.level
            }
          end)
      end
    end)
    |> List.flatten()
  end

  defp build_unit_rewards_params(user_id, unit_rewards) do
    Enum.map(unit_rewards, fn unit_reward ->
      Units.get_unit(unit_reward.unit_id)
      |> case do
        {:ok, unit} ->
          Enum.map(1..unit_reward.amount, fn _ ->
            %{
              user_id: user_id,
              character_id: unit.character_id,
              unit_level: unit.level,
              tier: unit.tier,
              selected: false
            }
          end)
      end
    end)
    |> List.flatten()
  end

  # defp apply_unit_rewards(user_id, unit_rewards) do
  #   Enum.map(unit_rewards, fn unit_reward ->
  #     Units.get_unit(unit_reward.unit_id)
  #     |> case do
  #       {:ok, unit} ->
  #         Enum.each(1..unit_reward.amount, fn _ ->
  #           Units.insert_unit(%{
  #             user_id: user_id,
  #             character_id: unit.character_id,
  #             unit_level: unit.level,
  #             tier: unit.tier,
  #             selected: false
  #           })
  #         end)

  #         {:ok, unit}

  #       {:error, _} ->
  #         {:error, "Failed to apply unit rewards"}
  #     end
  #   end)
  #   |> check_result(:unit_rewards)
  # end

  defp check_result(result, element_name) do
    if Enum.all?(result, fn
         {:ok, _} -> true
         _ -> false
       end) do
      {:ok, result}
    else
      {:error, "Failed to apply " <> Atom.to_string(element_name)}
    end
  end
end
