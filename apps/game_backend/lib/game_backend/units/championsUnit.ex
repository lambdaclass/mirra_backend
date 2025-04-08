defmodule GameBackend.Units.ChampionsUnit do
  @moduledoc """
  Units are instances of characters tied to a user.

  Slots must not be assigned the value `0`, since this is the way Protobuf sends nil values.
  """

  use GameBackend.Schema
  import Ecto.Changeset
  alias GameBackend.Units.Characters.Character
  alias GameBackend.Users.User

  schema "champions_units" do
    field(:level, :integer)

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
      :character_id,
      :user_id,
    ])
    |> validate_required([:level, :character_id, :user_id])
  end
end
