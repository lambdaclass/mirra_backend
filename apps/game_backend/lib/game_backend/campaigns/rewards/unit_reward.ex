defmodule GameBackend.Campaigns.Rewards.UnitReward do
  @moduledoc """
  The representation of a level reward that gives a unit to the user.
  """

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Campaigns.Level
  alias GameBackend.Units.Characters.Character

  schema "unit_rewards" do
    belongs_to(:character, Character)
    belongs_to(:level, Level)
    field(:amount, :integer)
    field(:rank, :integer)

    timestamps()
  end

  @doc false
  def changeset(unit_reward, attrs) do
    unit_reward
    |> cast(attrs, [:character_id, :level_id, :amount, :rank])
    |> validate_number(:amount, greater_than_or_equal_to: 0)
    |> validate_required([:amount, :rank])
  end
end
