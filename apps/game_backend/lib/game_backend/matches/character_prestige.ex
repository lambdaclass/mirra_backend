defmodule GameBackend.Matches.CharacterPrestige do
  @moduledoc """
  Prestige for each character of a User
  """

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Users.User

  schema "character_prestiges" do
    field(:character, :string)
    field(:amount, :integer)
    field(:rank, :string)
    field(:sub_rank, :integer)

    belongs_to(:user, User)

    timestamps()
  end

  def changeset(user_currency, attrs) do
    user_currency
    |> cast(attrs, [:amount, :character, :rank, :sub_rank, :user_id])
    |> validate_required([:amount, :character, :rank, :sub_rank, :user_id])
    |> validate_number(:amount, greater_than_or_equal_to: 0)
    |> validate_number(:sub_rank, greater_than_or_equal_to: 0)
    |> validate_inclusion(:rank, ["bronze", "silver", "gold", "platinum", "diamond", "champion", "grandmaster"])
  end
end
