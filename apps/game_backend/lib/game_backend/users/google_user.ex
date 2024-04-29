defmodule GameBackend.Users.GoogleUser do
  @moduledoc """
  Google Users.
  """

  use GameBackend.Schema
  import Ecto.Changeset

  schema "google_users" do
    field(:email, :string)
    has_one(:user, User)
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
