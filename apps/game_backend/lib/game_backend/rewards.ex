defmodule GameBackend.Rewards do
  @moduledoc """
  Operations with Rewards.
  """

  import Ecto.Query
  alias GameBackend.Repo
  alias GameBackend.Campaigns.Rewards.AfkRewardRate

  @doc """
  Inserts an AfkRewardRate.
  """
  def insert_afk_reward_rate(attrs) do
    %AfkRewardRate{}
    |> AfkRewardRate.changeset(attrs)
    |> Repo.insert()
  end

  def get_afk_reward_rate(user_id, currency_id) do
    Repo.one(
      from(afk in AfkRewardRate,
        where: afk.user_id == ^user_id and afk.currency_id == ^currency_id,
        select: afk
      )
    )
  end

  def increment_afk_reward_rate(user_id, currency_id, rate_increment) do
    afk_reward_rate = get_afk_reward_rate(user_id, currency_id)

    case afk_reward_rate do
      nil ->
        {:error, :not_found}

      _ ->
        AfkRewardRate.changeset(afk_reward_rate, %{
          rate: afk_reward_rate.rate + rate_increment
        })
        |> Repo.update()
    end
  end
end
