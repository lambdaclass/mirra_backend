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

  schema "levels" do
    field(:game_id, :integer)
    field(:level_number, :integer)

    belongs_to(:campaign, Campaign)
    has_many(:units, Unit)
    has_many(:currency_rewards, CurrencyReward)
    has_many(:item_rewards, ItemReward)
    has_many(:unit_rewards, UnitReward)

    timestamps()
  end

  @spec changeset(
          {map(), map()}
          | %{
              :__struct__ => atom() | %{:__changeset__ => map(), optional(any()) => any()},
              optional(atom()) => any()
            }
        ) :: Ecto.Changeset.t()
  @doc false
  def changeset(level, attrs \\ %{}) do
    level
    |> cast(attrs, [:game_id, :level_number, :campaign_id])
    |> cast_assoc(:units)
    |> cast_assoc(:currency_rewards)
    |> cast_assoc(:item_rewards)
    |> cast_assoc(:unit_rewards)
    |> validate_required([:game_id, :level_number, :campaign_id])
  end

  @doc """
  Changeset for editing a level's basic attributes.
  """
  def edit_changeset(level, attrs), do: cast(level, attrs, [:level_number, :campaign_id])
end
