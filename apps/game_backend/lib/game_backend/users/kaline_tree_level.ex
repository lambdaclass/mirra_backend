defmodule GameBackend.Users.KalineTreeLevel do
  @moduledoc """
  Kaline Tree Levels indicate the overarching progress of the player within the game.
  Advancing the Kaline Tree unlocks new features in the game.
  The Tree’s level can be raised by spending the currencies set in level_up_cost.
  """
  use GameBackend.Schema
  import Ecto.Changeset
  alias GameBackend.Users.Currencies.CurrencyCost
  alias GameBackend.Campaigns.Rewards.AfkRewardRate

  schema "kaline_tree_levels" do
    field(:level, :integer)

    # TODO: Implement unlock features (like new supercampaigns, new mechanics, etc.)
    field(:unlock_features, {:array, :string})

    embeds_many(:level_up_cost, CurrencyCost, on_replace: :delete)
    has_many(:afk_reward_rates, AfkRewardRate)
    field(:experience_reward_rate, :float)

    timestamps()
  end

  @doc false
  def changeset(kaline_tree_level, attrs) do
    kaline_tree_level
    |> cast(attrs, [:level, :unlock_features, :experience_reward_rate])
    |> cast_embed(:level_up_cost)
    |> cast_assoc(:afk_reward_rates)
    |> validate_required([:level])
  end
end
