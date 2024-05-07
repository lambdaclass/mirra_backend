defmodule GameBackend.Units.Skills.Mechanics.TargetingStrategy do
  @moduledoc """
  A schema that defines the strategy for how a mechanic will choose its targets.
  """

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Units.Skills.Mechanics.TargetingStrategies

  @primary_key false
  embedded_schema do
    field(:type, TargetingStrategies.Type)
    field(:count, :integer)
    field(:target_allies, :boolean)
  end

  @doc false
  def changeset(targeting_strategy, attrs \\ %{}) do
    targeting_strategy
    |> cast(attrs, [:type, :count, :target_allies])
    |> validate_required([:type])
  end
end
