defmodule GameBackend.Users.GoogleUser do
  @moduledoc """
  Google Users.
  """

  use GameBackend.Schema
  import Ecto.Changeset

  schema "google_users" do
    field(:email, :string)
    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email])
    |> validate_required([:email])
  end
end
