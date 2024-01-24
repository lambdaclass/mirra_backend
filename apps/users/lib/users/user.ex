defmodule Users.User do
  @moduledoc """
  Users.
  """

  use Users.Schema
  import Ecto.Changeset
  alias Items.Item
  alias Units.Unit

  @derive {Jason.Encoder, only: [:id, :username, :units, :items]}
  schema "users" do
    field(:game_id, :integer)
    field(:username, :string)

    has_many(:units, Unit)
    has_many(:items, Item)

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
