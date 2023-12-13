defmodule DarkWorldsServer.Skill do
  use Ecto.Schema
  import Ecto.Changeset

  alias DarkWorldsServer.Effect
  alias DarkWorldsServer.Skill.SkillMechanic

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "skills" do
    field(:name, :string)
    field(:cooldown_ms, :integer)
    field(:execution_duration_ms, :integer)
    field(:is_passive, :boolean)

    embeds_many(:mechanics, SkillMechanic)

    timestamps()
  end

  @doc false
  def changeset(skill, attrs) do
    skill
    |> cast(attrs, [:name, :cooldown_ms, :execution_duration_ms, :is_passive])
    |> cast_embed(:mechanics)
    |> validate_required([:name, :cooldown_ms, :execution_duration_ms, :is_passive, :mechanics])
  end

  defmodule SkillMechanic do
    use Ecto.Schema

    embedded_schema do
      # GiveEffect, Hit, SimpleShoot, MultiShoot, MoveToTarget
      field(:type, :string)

      # GiveEffect
      embeds_many(:effects, Effect)

      # Hit
      field(:damage, :integer)
      field(:range, :integer)
      field(:on_hit_effects, {:array, :string})

      # Hit & MultiShoot
      field(:cone_angle, :integer)

      # SimpleShoot & MultiShoot
      field(:projectile, :string)

      # MultiShoot
      field(:count, :integer)

      # MoveToTarget
      field(:duration_ms, :integer)
      field(:max_range, :integer)
    end

    def changeset(skill_mechanic, attrs) do
      skill_mechanic
      |> cast(attrs, [
        :type,
        :damage,
        :range,
        :on_hit_effects,
        :cone_angle,
        :projectile,
        :count,
        :duration_ms,
        :max_range
      ])
      |> cast_embed(:effects)
    end
  end
end
