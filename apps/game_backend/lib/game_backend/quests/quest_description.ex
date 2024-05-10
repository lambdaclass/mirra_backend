defmodule GameBackend.Quests.QuestDescription do
  @moduledoc """

  """

  use GameBackend.Schema
  import Ecto.Changeset

  schema "quest_descriptions" do
    field(:description, :string)
    field(:type, :string)
    field(:quest_objectives, {:array, :map})

    timestamps()
  end

  @types ["daily"]

  def types, do: @types

  @required [
    :description,
    :quest_objectives
  ]

  @permitted [] ++ @required

  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, @permitted)
    |> validate_required(@required)
    |> validate_inclusion(:type, @types)
  end
end
