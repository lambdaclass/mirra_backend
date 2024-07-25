defmodule GameBackend.Rewards do
  @moduledoc """
  Operations with Rewards.
  """

  import Ecto.Query
  alias Ecto.Multi
  alias GameBackend.Repo
  alias GameBackend.Campaigns.Rewards.AfkRewardRate
  alias GameBackend.Utils
  alias GameBackend.Users
  alias GameBackend.Users.Currencies

  @doc """
  Inserts an AfkRewardRate.
  """
  def insert_afk_reward_rate(attrs) do
    %AfkRewardRate{}
    |> AfkRewardRate.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets the AfkRewardRate for a user and a currency.
  Returns `{:error, :not_found}` if no AfkRewardRate is found.
  """
  def get_afk_reward_rate(user_id, currency_id) do
    afk_reward_rate =
      Repo.one(
        from(afk in AfkRewardRate,
          where: afk.user_id == ^user_id and afk.currency_id == ^currency_id,
          select: afk
        )
      )

    if afk_reward_rate, do: {:ok, afk_reward_rate}, else: {:error, :not_found}
  end

  def increment_afk_reward_rate(user_id, currency_id, daily_rate_increment) do
    case get_afk_reward_rate(user_id, currency_id) do
      {:ok, afk_reward_rate} ->
        afk_reward_rate
        |> AfkRewardRate.changeset(%{daily_rate: afk_reward_rate.daily_rate + daily_rate_increment})
        |> Repo.update()

      {:error, :not_found} ->
        insert_afk_reward_rate(%{user_id: user_id, currency_id: currency_id, daily_rate: daily_rate_increment})
    end
  end

  @doc """
  Receives a user.
  Returns the next daily reward for the given user.
  Or the first claim if never claimed at all.
  """
  def claim_daily_reward(%GameBackend.Users.User{last_daily_reward_claim_at: nil}),
    do: claim_first_reward(Utils.get_daily_rewards_config())

  def claim_daily_reward(user) do
    daily_reward_config = Utils.get_daily_rewards_config()
    yesterday = DateTime.utc_now() |> Date.add(-1)

    case Date.compare(user.last_daily_reward_claim_at, yesterday) do
      :eq -> claim_todays_reward(daily_reward_config, user.last_daily_reward_claim)
      _ -> claim_first_reward(daily_reward_config)
    end
  end

  defp claim_first_reward(daily_reward_config) do
    case Map.get(daily_reward_config, "day_1") do
      nil -> {:error, :invalid_reward}
      first_daily_reward -> {:ok, first_daily_reward |> Map.put("day", "day_1")}
    end
  end

  defp claim_todays_reward(daily_reward_config, last_daily_reward_claim) do
    case Map.get(daily_reward_config, last_daily_reward_claim) do
      nil ->
        {:error, :invalid_reward}

      last_reward ->
        {:ok, Map.get(daily_reward_config, last_reward["next_reward"]) |> Map.put("day", last_reward["next_reward"])}
    end
  end

  @doc """
  Receives a user.
  Returns {:ok, can_claim} if the user claimed today already or never claimed at all.
  """
  def user_can_claim(%GameBackend.Users.User{last_daily_reward_claim_at: nil}), do: {:ok, :can_claim}

  def user_can_claim(user) do
    now = DateTime.utc_now()

    case Date.compare(user.last_daily_reward_claim_at, now) do
      :eq -> {:error, :already_claimed}
      _ -> {:ok, :can_claim}
    end
  end

  defp user_in_daily_rewards_streak?(%GameBackend.Users.User{last_daily_reward_claim_at: nil}), do: false

  defp user_in_daily_rewards_streak?(user) do
    today = DateTime.utc_now()
    yesterday = today |> Date.add(-1)

    Date.compare(user.last_daily_reward_claim_at, today) == :eq or
      Date.compare(user.last_daily_reward_claim_at, yesterday) == :eq
  end

  def mark_user_daily_rewards_as_completed(daily_rewards_config, user) do
    if user_in_daily_rewards_streak?(user) do
      Map.new(daily_rewards_config, fn {day, _reward_info} ->
        if day <= user.last_daily_reward_claim, do: {day, "claimed"}, else: {day, "not claimed"}
      end)
    else
      Map.new(daily_rewards_config, fn {day, _reward_info} -> {day, "not claimed"} end)
    end
  end

  @doc """
  Receives a user and a daily_reward params map.
  Updates the user's daily_reward fields and also add the currency rewards to that user.
  Returns {:ok, map_of_ran_operations} in case of success.
  Returns {:error, failed_operation, failed_value, changes_so_far} if one of the operations fail.
  """
  def update_user_due_to_daily_rewards_claim(user, daily_reward) do
    Multi.new()
    |> Multi.run(:update_user, fn _, _ ->
      Users.update_user(user, %{
        last_daily_reward_claim_at: DateTime.utc_now(),
        last_daily_reward_claim: daily_reward["day"]
      })
    end)
    |> Multi.run(:update_user_currencies, fn _, _ ->
      Currencies.add_currency_by_name_and_game!(
        user.id,
        daily_reward["currency"],
        Utils.get_game_id(:curse_of_mirra),
        daily_reward["amount"]
      )
    end)
    |> Repo.transaction()
  end
end
