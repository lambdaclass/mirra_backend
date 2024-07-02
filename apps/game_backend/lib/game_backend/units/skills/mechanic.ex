defmodule GameBackend.Units.Skills.Mechanic do
  @moduledoc false

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Units.Skills.Skill
  alias GameBackend.Units.Skills.Mechanics.{ApplyEffectsTo, PassiveEffect}

  schema "mechanics" do
    field(:amount, :integer)
    field(:angle_between, :decimal)
    field(:damage, :integer)
    field(:duration_ms, :integer)
    field(:effects_to_apply, {:array, :string})
    field(:interval_ms, :integer)
    field(:move_by, :decimal)
    field(:name, :string)
    field(:offset, :integer)
    field(:projectile_offset, :integer)
    field(:radius, :decimal)
    field(:range, :decimal)
    field(:remove_on_collision, :boolean, default: false)
    field(:speed, :decimal)
    field(:trigger_delay, :integer)

    field(:type, Ecto.Enum,
      values: [:circle_hit, :spawn_pool, :leap, :multi_shoot, :dash, :multi_circle_hit, :teleport, :simple_shoot]
    )

    belongs_to(:skill, Skill)
    belongs_to(:apply_effects_to, ApplyEffectsTo)
    # Not yet implemented, added to define how different Mechanic types will be handled
    belongs_to(:passive_effects, PassiveEffect)
    belongs_to(:on_arrival_mechanic, __MODULE__)
    belongs_to(:on_explode_mechanic, __MODULE__)
  end

  def mechanic_types(), do: [:apply_effects_to, :passive_effects]

  @doc false
  def changeset(mechanic, attrs \\ %{}) do
    mechanic
    |> cast(attrs, [
      :trigger_delay,
      :skill_id,
      :type,
      :amount,
      :angle_between,
      :damage,
      :duration_ms,
      :effects_to_apply,
      :interval_ms,
      :move_by,
      :name,
      :offset,
      :projectile_offset,
      :radius,
      :range,
      :remove_on_collision,
      :speed
    ])
    |> cast_assoc(:apply_effects_to)
    |> cast_assoc(:passive_effects)
    |> cast_assoc(:on_arrival_mechanic, with: &assoc_changeset/2)
    |> cast_assoc(:on_explode_mechanic, with: &assoc_changeset/2)
  end

  defp assoc_changeset(struct, params) do
    changeset = changeset(struct, params)

    case get_field(changeset, :type) do
      nil -> %{changeset | action: :ignore}
      _ -> changeset
    end
  end
end
