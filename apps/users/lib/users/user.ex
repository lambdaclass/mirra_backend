defmodule Users.User do
  @moduledoc """
  Users.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:username, :string)

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username])
    |> validate_required([:username])
  end

  @doc """
  Changeset for setting a user's character id.
  """
  def character_changeset(user, attrs) do
    user
    |> cast(attrs, [:username])
    |> validate_required([:username])
  end
end
