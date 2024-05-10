defmodule GameBackend.Quests.QuestDescription do
  @moduledoc """

  """

  use GameBackend.Schema
  import Ecto.Changeset

  schema "quest_descriptions" do
    field(:description, :string)
    field(:quest_objectives, {:array, :map})

    timestamps()
  end

  @required [
    :description,
    :quest_objectives
  ]

  @permitted [] ++ @required

  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, @permitted)
    |> validate_required(@required)
  end
end
