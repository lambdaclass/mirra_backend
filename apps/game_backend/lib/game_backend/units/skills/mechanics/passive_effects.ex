defmodule GameBackend.Units.Skills.Mechanics.PassiveEffects do
  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Units.Skills.Mechanics.Effect

  schema "passive_effects" do
    embeds_many(:effects, Effect)
  end

  @doc false
  def changeset(passive_effects, attrs \\ %{}) do
    passive_effects
    |> cast(attrs, [])
    |> cast_embed(:effects)
  end
end
