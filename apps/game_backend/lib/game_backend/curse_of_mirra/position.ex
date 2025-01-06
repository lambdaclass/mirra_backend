defmodule GameBackend.CurseOfMirra.Position do
  @moduledoc """
  Position embedded schema to be used by MapConfiguration
  """
  use GameBackend.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:x, :y]}
  embedded_schema do
    field(:x, :decimal)
    field(:y, :decimal)
  end

  def changeset(position, attrs) do
    position
    |> cast(attrs, [:x, :y])
    |> validate_required([:x, :y])
  end
end
