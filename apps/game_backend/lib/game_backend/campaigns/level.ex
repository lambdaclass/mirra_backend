defmodule GameBackend.Campaigns.Level do
  @moduledoc """
  Levels
  """

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Users.Currencies.CurrencyCost
  alias GameBackend.Campaigns.Rewards.CurrencyReward
  alias GameBackend.Campaigns.Rewards.UnitReward
  alias GameBackend.Campaigns.Rewards.ItemReward
  alias GameBackend.Campaigns.Campaign
  alias GameBackend.Units.Unit

  schema "levels" do
    field(:game_id, :integer)
    field(:level_number, :integer)
    field(:experience_reward, :integer)
    field(:is_boss_stage?, :boolean, default: false)

    field(:max_units, :integer)
    has_many(:units, Unit, foreign_key: :campaign_level_id, on_replace: :delete)

    belongs_to(:campaign, Campaign)
    has_many(:currency_rewards, CurrencyReward, on_replace: :delete)
    has_many(:item_rewards, ItemReward)
    has_many(:unit_rewards, UnitReward)

    embeds_many(:attempt_cost, CurrencyCost, on_replace: :delete)
    timestamps()
  end

  @doc false
  def changeset(level, attrs \\ %{}) do
    level
    |> cast(attrs, [:game_id, :level_number, :campaign_id, :experience_reward, :max_units, :is_boss_stage?])
    |> cast_assoc(:units)
    |> cast_assoc(:currency_rewards)
    |> cast_assoc(:item_rewards)
    |> cast_assoc(:unit_rewards)
    |> cast_embed(:attempt_cost)
    |> validate_required([:game_id, :level_number, :campaign_id])
  end
end
