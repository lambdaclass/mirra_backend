defmodule GameBackend.Campaigns.Rewards.AfkRewardRate do
  @moduledoc """
  The representation of a Kaline Tree AFK reward rate that periodically gives a currency to the user in that level of the Tree.
  """

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Users.Currencies.Currency
  alias GameBackend.Users.DungeonSettlementLevel
  alias GameBackend.Users.KalineTreeLevel

  schema "afk_reward_rates" do
    belongs_to(:kaline_tree_level, KalineTreeLevel)
    belongs_to(:dungeon_settlement_level, DungeonSettlementLevel)
    belongs_to(:currency, Currency)
    field(:rate, :float)

    timestamps()
  end

  @doc false
  def changeset(afk_reward_rate, attrs) do
    afk_reward_rate
    |> cast(attrs, [:kaline_tree_level_id, :dungeon_settlement_level_id, :currency_id, :rate])
    |> validate_number(:rate, greater_than_or_equal_to: 0)
    |> validate_required([:currency_id, :rate])
  end
end
