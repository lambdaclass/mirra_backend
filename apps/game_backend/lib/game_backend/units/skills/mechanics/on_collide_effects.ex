defmodule GameBackend.Units.Skills.Mechanics.OnCollideEffects do
  @moduledoc """
  A schema that defines the strategy for how a mechanic will choose its targets.
  """

  use GameBackend.Schema
  import Ecto.Changeset

  @derive Jason.Encoder
  @primary_key false
  embedded_schema do
    field(:apply_effect_to_entity_type, {:array, :string})
    field(:effects, {:array, :string})
  end

  @doc false
  def changeset(targeting_strategy, attrs \\ %{}) do
    targeting_strategy
    |> cast(attrs, [:apply_effect_to_entity_type, :effects])
  end
end
