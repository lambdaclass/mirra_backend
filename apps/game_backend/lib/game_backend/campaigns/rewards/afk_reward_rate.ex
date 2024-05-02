defmodule GameBackend.Campaigns.Rewards.AfkRewardRate do
  @moduledoc """
  The representation of a Kaline Tree level reward that gives a currency to the user.
  """

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Users.KalineTreeLevel
  alias GameBackend.Users.Currencies.Currency

  schema "afk_reward_rates" do
    belongs_to(:kaline_tree_level, KalineTreeLevel)
    belongs_to(:currency, Currency)
    field(:rate, :float)

    timestamps()
  end

  @doc false
  def changeset(afk_reward_rate, attrs) do
    afk_reward_rate
    |> cast(attrs, [:kaline_tree_level_id, :currency_id, :rate])
    |> validate_number(:rate, greater_than_or_equal_to: 0)
    |> validate_required([:kaline_tree_level_id, :currency_id, :rate])
  end
end
