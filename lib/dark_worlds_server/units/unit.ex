defmodule DarkWorldsServer.Units.Unit do
  @moduledoc """
  Units are instances of characters tied to a user.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias DarkWorldsServer.Config.Characters.Character
  alias DarkWorldsServer.Units.User

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
  def changeset(character, attrs) do
    character
    |> cast(attrs, [:level, :selected, :position, :character_id, :user_id])
    |> validate_required([:level, :selected, :position, :character_id, :user_id])
  end
end
