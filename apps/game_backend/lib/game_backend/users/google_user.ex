defmodule GameBackend.Users.GoogleUser do
  @moduledoc """
  Google Users.
  """

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Matches.ArenaMatchResult

  schema "google_users" do
    field(:email, :string)
    has_one(:user, GameBackend.Users.User)
    has_many(:arena_match_results, ArenaMatchResult)
    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email])
    |> cast_assoc(:user, with: &GameBackend.Users.User.changeset/2)
    |> validate_required([:email, :user])
  end
end
