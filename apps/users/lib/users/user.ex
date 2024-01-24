defmodule Users.User do
  @moduledoc """
  Users.
  """

  use Users.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:username]}
  schema "users" do
    field(:game_id, :integer)
    field(:username, :string)

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:game_id, :username])
    |> validate_required([:game_id, :username])
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
