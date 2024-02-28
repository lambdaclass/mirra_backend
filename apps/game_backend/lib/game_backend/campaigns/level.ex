defmodule GameBackend.Campaigns.Level do
  @moduledoc """
  Levels
  """

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Items.ItemReward
  alias GameBackend.Campaigns.Rewards.CurrencyReward
  alias GameBackend.Campaigns.Rewards.UnitReward
  alias GameBackend.Campaigns.Rewards.ItemReward
  alias GameBackend.Campaigns.Campaign
  alias GameBackend.Units.Unit

  @derive {Jason.Encoder, only: [:id, :level_number, :campaign, :units]}
  schema "levels" do
    field(:game_id, :integer)
    field(:level_number, :integer)
    field(:experience_reward, :integer)

    belongs_to(:campaign, Campaign)
    has_many(:units, Unit)
    has_many(:currency_rewards, CurrencyReward)
    has_many(:afk_rewards_increments, CurrencyReward)
    has_many(:item_rewards, ItemReward)
    has_many(:unit_rewards, UnitReward)

    timestamps()
  end

  @doc false
  def changeset(level, attrs \\ %{}) do
    level
    |> cast(attrs, [:game_id, :level_number, :campaign_id, :experience_reward])
    |> cast_assoc(:units)
    |> cast_assoc(:currency_rewards)
    |> cast_assoc(:afk_rewards_increments)
    |> cast_assoc(:item_rewards)
    |> cast_assoc(:unit_rewards)
    |> validate_required([:game_id, :level_number, :campaign_id])
  end
end
