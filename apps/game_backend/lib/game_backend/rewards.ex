defmodule GameBackend.Rewards do
  @moduledoc """
  Operations with Rewards.
  """

  import Ecto.Query
  alias GameBackend.Repo
  alias GameBackend.Campaigns.Rewards.AfkRewardRate
  alias GameBackend.Utils

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

  def increment_afk_reward_rate(user_id, currency_id, rate_increment) do
    case get_afk_reward_rate(user_id, currency_id) do
      {:ok, afk_reward_rate} ->
        afk_reward_rate
        |> AfkRewardRate.changeset(%{rate: afk_reward_rate.rate + rate_increment})
        |> Repo.update()

      {:error, :not_found} ->
        insert_afk_reward_rate(%{user_id: user_id, currency_id: currency_id, rate: rate_increment})
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
      :eq -> claim_next_reward(daily_reward_config, user.last_daily_reward_claim)
      _ -> claim_first_reward(daily_reward_config)
    end
  end

  defp claim_first_reward(daily_reward_config) do
    case Map.get(daily_reward_config, "1") do
      nil -> {:error, :invalid_reward}
      first_daily_reward -> {:ok, first_daily_reward}
    end
  end

  defp claim_next_reward(daily_reward_config, current_reward) do
    case Map.get(daily_reward_config, current_reward) do
      nil -> {:error, :invalid_reward}
      next_daily_reward -> {:ok, next_daily_reward}
    end
  end

  @doc """
  Receives a user.
  Returns {:ok, can_claim} if the user claimed today already or never claimed at all.
  """
  def user_claimed_today(%GameBackend.Users.User{last_daily_reward_claim_at: nil}), do: {:ok, :can_claim}

  def user_claimed_today(user) do
    now = DateTime.utc_now()

    case Date.compare(user.last_daily_reward_claim_at, now) do
      :eq -> {:ok, :can_claim}
      _ -> {:error, :already_claimed}
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
      Map.new(daily_rewards_config, fn {day, _next_reward} ->
        last_claim = String.to_integer(user.last_daily_reward_claim)
        current_day = String.to_integer(day)
        if last_claim <= current_day, do: {day, "claimed"}, else: {day, "not claimed"}
      end)
    else
      Map.new(daily_rewards_config, fn {day, _next_reward} -> {day, "not claimed"} end)
    end
  end
end
