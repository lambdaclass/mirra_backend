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
        AfkRewardRate.changeset(afk_reward_rate, %{
          rate: afk_reward_rate.rate + rate_increment
        })
        |> Repo.update()

      {:error, :not_found} ->
        # TODO: Should create it if there is none, like we do with currencies [#CHoM-223]
        {:error, :not_found}
    end
  end
end
