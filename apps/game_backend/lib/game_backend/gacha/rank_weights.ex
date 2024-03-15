defmodule GameBackend.Gacha.RankWeights do
  @moduledoc """
  Embedded schema for boxes' rank weights.
  """
  use GameBackend.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:rank, :integer)
    field(:weight, :integer)
  end

  @doc false
  def changeset(currency_cost, attrs),
    do:
      currency_cost
      |> cast(attrs, [:rank, :weight])
      |> validate_required([:rank, :weight])
end
