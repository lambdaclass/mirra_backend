defmodule GameBackend.Units.Unit do
  @moduledoc """
  Units are instances of characters tied to a user.

  Slots must not be assigned the value `0`, since this is the way Protobuf sends nil values.
  """

  use GameBackend.Schema
  import Ecto.Changeset
  alias GameBackend.Campaigns.Level
  alias GameBackend.Items.Item
  alias GameBackend.Units.Characters.Character
  alias GameBackend.Users.User

  schema "units" do
    field(:level, :integer)
    field(:tier, :integer)
    field(:rank, :integer)
    field(:sub_rank, :integer)
    field(:selected, :boolean)
    field(:slot, :integer)
    field(:prestige, :integer)

    belongs_to(:campaign_level, Level)
    belongs_to(:user, User)
    belongs_to(:character, Character)

    has_many(:items, Item)

    timestamps()
  end

  @doc false
  def changeset(unit, attrs) do
    unit
    |> cast(attrs, [
      :level,
      :tier,
      :rank,
      :selected,
      :slot,
      :character_id,
      :user_id,
      :campaign_level_id,
      :prestige
    ])
    |> validate_required([:level, :selected, :character_id])
  end

  @doc """
  Changeset for when updating a unit.
  """
  def update_changeset(unit, attrs),
    do: cast(unit, attrs, [:selected, :slot, :level, :tier, :rank])

  def curse_of_mirra_update_changeset(unit, attrs) do
    unit
    |> cast(attrs, [:level, :rank, :sub_rank])
    |> common_changeset()
  end

  defp common_changeset(changeset) do
    changeset
    |> validate_required([:level, :rank, :sub_rank, :user_id, :character_id])
    |> validate_number(:level, greater_than_or_equal_to: 0)
    |> validate_number(:rank, greater_than: 0)
    |> validate_number(:sub_rank, greater_than_or_equal_to: 0)
    |> validate_number(:prestige, greater_than_or_equal_to: 0)
  end
end
