defmodule DarkWorldsServer.Units.Unit do
  @moduledoc """
  Units are instances of characters tied to a user.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias DarkWorldsServer.Config.Characters.Character
  alias DarkWorldsServer.Units.UserUnit

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "units" do
    field(:level, :integer)
    field(:selected, :boolean)
    field(:position, :integer)

    has_one(:user_unit, UserUnit)
    has_one(:user, through: [:user_unit, :user])

    belongs_to(:character, Character)

    timestamps()
  end

  @doc false
  def changeset(character, attrs) do
    character
    |> cast(attrs, [:level, :selected, :position, :character_id])
    |> validate_required([:level, :selected, :position, :character_id])
  end
end
