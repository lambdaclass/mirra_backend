defmodule GameBackend.Quests.Quest do
  @moduledoc """

  """

  use GameBackend.Schema
  import Ecto.Changeset

  schema "quests" do
    field(:description, :string)
    field(:type, :string)
    field(:target, :integer)
    field(:objectives, {:array, :map})

    timestamps()
  end

  @types ["daily"]

  def types, do: @types

  @required [
    :description,
    :objectives,
    :type,
    :target
  ]

  @permitted [] ++ @required

  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, @permitted)
    |> validate_required(@required)
    |> validate_inclusion(:type, @types)
  end
end
