defmodule GameBackend.Common.DemoCurrency do
  @moduledoc """
  Demo Users
  """
  use GameBackend.Schema, prefix: "common"
  import Ecto.Changeset

  schema "demo_currencies" do
    field(:name, :string)

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
