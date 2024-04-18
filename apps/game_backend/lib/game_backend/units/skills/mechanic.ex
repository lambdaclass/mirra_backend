defmodule GameBackend.Units.Skills.Mechanic do
  @moduledoc false

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Units.Skills.Skill
  alias GameBackend.Units.Skills.Mechanics.{ApplyEffectsTo, PassiveEffects}

  schema "mechanics" do
    field(:trigger_delay, :integer)
    belongs_to(:skill, Skill)

    belongs_to(:apply_effects_to, ApplyEffectsTo)
    # Not yet implemented, added to define how different Mechanic types will be handled
    belongs_to(:passive_effects, PassiveEffects)
  end

  @doc false
  def changeset(mechanic, attrs \\ %{}) do
    mechanic
    |> cast(attrs, [:trigger_delay, :skill_id])
    |> cast_assoc(:apply_effects_to)
    |> cast_assoc(:passive_effects)
    |> validate_only_one_type()
  end

  defp validate_only_one_type(changeset) do
    if Enum.count(mechanic_types(), fn type -> Map.has_key?(changeset.changes, type) end) == 1,
      do: changeset,
      else:
        add_error(
          changeset,
          hd(mechanic_types()),
          "Exactly 1 of these fields must be present: #{inspect(mechanic_types())}"
        )
  end

  def mechanic_types(), do: [:apply_effects_to, :passive_effects]
end
