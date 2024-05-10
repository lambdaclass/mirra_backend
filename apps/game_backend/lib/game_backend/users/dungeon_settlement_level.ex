defmodule GameBackend.Users.DungeonSettlementLevel do
  @moduledoc """
  DungeonSettlementLevels indicate the level of a dungeon settlement.
  Dungeon Settlements are the overarching progression mechanic of the Dungeon mode.
  They define the amount of supplies a player can hold, and limit the max level of dungeons that can be accessed.
  """
  use GameBackend.Schema

  import Ecto.Changeset

  alias GameBackend.Campaigns.Rewards.AfkRewardRate
  alias GameBackend.Users.Currencies.CurrencyCost

  schema "dungeon_settlement_levels" do
    field(:level, :integer)

    # The max dungeon level that can be accessed at this level
    field(:max_dungeon, :integer)

    # The max factional dungeon level that can be accessed at this level
    field(:max_factional, :integer)

    # The amount of Supplies currency that a player can hold at a time // TODO: [#CHoM-439]
    field(:supply_limit, :integer)

    has_many(:afk_reward_rates, AfkRewardRate)

    embeds_many(:upgrade_costs, CurrencyCost)

    timestamps()
  end

  @doc false
  def changeset(dungeon_settlement_level, attrs) do
    dungeon_settlement_level
    |> cast(attrs, [:level, :max_dungeon, :max_factional, :supply_limit])
    |> cast_assoc(:afk_reward_rates)
    |> cast_embed(:upgrade_costs)
    |> validate_required([:level, :max_dungeon, :max_factional, :supply_limit])
  end
end
