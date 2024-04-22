defmodule GameBackend.Users.KalineTreeLevel do
  @moduledoc """
  Kaline Tree Levels.
  """
  use GameBackend.Schema
  import Ecto.Changeset

  schema "kaline_tree_levels" do
    field(:level, :integer)
    field(:fertilizer_cost, :integer)
    field(:gold_cost, :integer)
    field(:unlock_features, {:array, :string})
    timestamps()
  end

  @doc false
  def changeset(kaline_tree_level, attrs) do
    kaline_tree_level
    |> cast(attrs, [:level, :fertilizer_cost, :gold_cost, :unlock_features])
    |> validate_required([:level, :fertilizer_cost, :gold_cost])
  end
end
