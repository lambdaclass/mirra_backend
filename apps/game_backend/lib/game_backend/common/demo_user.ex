defmodule GameBackend.Common.DemoUser do
  @moduledoc """
  Demo Users
  """
  use GameBackend.Schema, prefix: "common"
  import Ecto.Changeset

  schema "demo_users" do
    field(:name, :string)
    field(:email, :string)

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email])
    |> unique_constraint([:email])
  end
end
