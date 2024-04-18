defmodule GameBackend.Units.Skills.Mechanics.ApplyEffectsTo do
  @moduledoc """
  A schema that combines an array of effects with the strategy it will decide the targets by.
  """

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Units.Skills.Mechanics.Effect
  alias GameBackend.Units.Skills.Mechanics.TargetingStrategy

  schema "apply_effects_to" do
    embeds_many(:effects, Effect, on_replace: :delete)
    embeds_one(:targeting_strategy, TargetingStrategy, on_replace: :delete)
  end

  @doc false
  def changeset(apply_effects_to, attrs \\ %{}) do
    apply_effects_to
    |> cast(attrs, [])
    |> cast_embed(:effects)
    |> cast_embed(:targeting_strategy)
  end
end
