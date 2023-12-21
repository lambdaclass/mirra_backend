defmodule DarkWorldsServer.Units.Unit do
  @moduledoc """
  Units are instances of characters tied to a user.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias DarkWorldsServer.Accounts.User
  alias DarkWorldsServer.Config.Characters.Character

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "units" do
    field(:level, :integer)
    field(:selected, :boolean)
    field(:slot, :integer)

    belongs_to(:user, User)
    belongs_to(:character, Character)

    timestamps()
  end

  @doc false
  def changeset(unit, attrs) do
    unit
    |> cast(attrs, [:level, :selected, :slot, :character_id, :user_id])
    |> validate_required([:level, :selected, :character_id, :user_id])
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
