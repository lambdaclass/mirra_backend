defmodule GameBackend.Users.KalineTreeLevel do
  @moduledoc """
  Kaline Tree Levels.
  """
  use GameBackend.Schema
  import Ecto.Changeset

  schema "kaline_tree_levels" do
    field(:level, :integer)
    field(:fertilizer_level_up_cost, :integer)
    field(:gold_level_up_cost, :integer)
    field(:unlock_features, {:array, :string})
    timestamps()
  end

  @doc false
  def changeset(kaline_tree_level, attrs) do
    kaline_tree_level
    |> cast(attrs, [:level, :fertilizer_level_up_cost, :gold_level_up_cost, :unlock_features])
    |> validate_required([:level, :fertilizer_level_up_cost, :gold_level_up_cost])
  end
end
