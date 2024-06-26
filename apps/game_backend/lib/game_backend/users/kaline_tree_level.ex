defmodule GameBackend.Users.KalineTreeLevel do
  @moduledoc """
  Kaline Tree Levels indicate the overarching progress of the player within the game.
  Advancing the Kaline Tree unlocks new features in the game.
  The Tree’s level can be upgraded spending Fertilizer and Gold.
  """
  use GameBackend.Schema
  import Ecto.Changeset
  alias GameBackend.Campaigns.Rewards.AfkRewardRate

  schema "kaline_tree_levels" do
    field(:level, :integer)
    field(:fertilizer_level_up_cost, :integer)
    field(:gold_level_up_cost, :integer)
    # TODO: Implement unlock features (like new supercampaigns, new mechanics, etc.)
    field(:unlock_features, {:array, :string})

    has_many(:afk_reward_rates, AfkRewardRate)

    timestamps()
  end

  @doc false
  def changeset(kaline_tree_level, attrs) do
    kaline_tree_level
    |> cast(attrs, [:level, :fertilizer_level_up_cost, :gold_level_up_cost, :unlock_features])
    |> cast_assoc(:afk_reward_rates)
    |> validate_required([:level, :fertilizer_level_up_cost, :gold_level_up_cost])
  end
end
