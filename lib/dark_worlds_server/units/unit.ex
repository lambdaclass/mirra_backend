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
    field(:position, :integer)

    belongs_to(:user, User)
    belongs_to(:character, Character)

    timestamps()
  end

  @doc false
  def changeset(unit, attrs) do
    unit
    |> cast(attrs, [:level, :selected, :position, :character_id, :user_id])
    |> validate_required([:level, :selected, :character_id, :user_id])
  end

  def selected_changeset(unit, attrs) do
    unit
    |> cast(attrs, [:selected])
    |> validate_required([:selected])
  end

  def character_changeset(unit, attrs) do
    unit
    |> cast(attrs, [:character_id])
    |> validate_required([:character_id])
  end
end
