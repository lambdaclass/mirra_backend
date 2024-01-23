defmodule Units.Unit do
  @moduledoc """
  Units are instances of characters tied to a user.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Users.User
  alias Units.Characters.Character

  schema "units" do
    field(:level, :integer)
    field(:tier, :integer)
    field(:selected, :boolean)
    field(:slot, :integer)

    belongs_to(:user, User)
    belongs_to(:character, Character)

    timestamps()
  end

  @doc false
  def changeset(unit, attrs) do
    unit
    |> cast(attrs, [:level, :tier, :selected, :slot, :character_id, :user_id])
    |> validate_required([:level, :tier, :selected, :character_id, :user_id])
  end

  @doc """
  Changeset for editing a unit's basic attributes.
  """
  def edit_changeset(unit, attrs), do: cast(unit, attrs, [:selected, :slot, :level])

  @doc """
  Changeset for setting a unit's character id.
  """
  def character_changeset(unit, attrs) do
    unit
    |> cast(attrs, [:character_id])
    |> validate_required([:character_id])
  end
end
