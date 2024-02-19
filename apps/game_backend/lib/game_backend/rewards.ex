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
end
