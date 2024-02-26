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
    field(:selected, :boolean)
    field(:slot, :integer)

    belongs_to(:campaign_level, Level)
    belongs_to(:user, User)
    belongs_to(:character, Character)

    has_many(:items, Item)

    timestamps()
  end

  @doc false
  def changeset(unit, attrs) do
    unit
    |> cast(attrs, [:level, :tier, :selected, :slot, :character_id, :user_id, :campaign_level_id])
    |> validate_required([:level, :tier, :selected, :character_id])
  end

  @doc """
  Changeset for when updating a units.
  """
  def update_changeset(unit, attrs),
    do: cast(unit, attrs, [:selected, :slot, :level, :tier])
end
