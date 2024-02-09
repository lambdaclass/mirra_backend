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

  @derive {Jason.Encoder,
           only: [:id, :unit_level, :tier, :selected, :slot, :level_id, :user_id, :character]}
  schema "units" do
    field(:unit_level, :integer)
    field(:tier, :integer)
    field(:rank, :integer)
    field(:selected, :boolean)
    field(:slot, :integer)

    belongs_to(:level, Level)
    belongs_to(:user, User)
    belongs_to(:character, Character)

    has_many(:items, Item)

    timestamps()
  end

  @doc false
  def changeset(unit, attrs) do
    unit
    |> cast(attrs, [
      :unit_level,
      :tier,
      :rank,
      :selected,
      :slot,
      :character_id,
      :user_id,
      :level_id
    ])
    |> validate_required([:unit_level, :tier, :rank, :selected, :character_id])
  end

  @doc """
  Changeset for when updating a unit.
  """
  def update_changeset(unit, attrs),
    do: cast(unit, attrs, [:selected, :slot, :unit_level, :tier, :rank])
end
