defmodule DarkWorldsServer.Characters.Skill do
  use Ecto.Schema
  import Ecto.Changeset

  alias DarkWorldsServer.Characters.Effect
  alias DarkWorldsServer.Characters.Skill.SkillMechanic

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
  def changeset(skill, attrs),
    do:
      skill
      |> cast(attrs, [:name, :cooldown_ms, :execution_duration_ms, :is_passive])
      |> cast_embed(:mechanics)
      |> validate_required([:name, :cooldown_ms, :execution_duration_ms, :is_passive, :mechanics])

  defmodule SkillMechanic do
    use Ecto.Schema

    @primary_key false
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

    def changeset(skill_mechanic, attrs), do: cast_and_validate_by_type(skill_mechanic, attrs)

    defp cast_and_validate_by_type(changeset, %{type: "GiveEffect"} = attrs),
      do:
        changeset
        |> cast(attrs, ~w(type)a)
        |> cast_embed(:effects)
        |> validate_required(:type)

    defp cast_and_validate_by_type(changeset, %{type: "Hit"} = attrs),
      do:
        changeset
        |> cast(attrs, ~w(type damage range on_hit_effects cone_angle)a)
        |> validate_required(~w(type damage range on_hit_effects cone_angle)a)

    defp cast_and_validate_by_type(changeset, %{type: "MultiShoot"} = attrs),
      do:
        changeset
        |> cast(attrs, ~w(type cone_angle projectile count)a)
        |> validate_required(~w(type cone_angle projectile count)a)

    defp cast_and_validate_by_type(changeset, %{type: "SimpleShoot"} = attrs),
      do:
        changeset
        |> cast(attrs, ~w(type projectile)a)
        |> validate_required(~w(type projectile)a)

    defp cast_and_validate_by_type(changeset, %{type: "MoveToTarget"} = attrs),
      do:
        changeset
        |> cast(attrs, ~w(type duration_ms max_range)a)
        |> validate_required(~w(type duration_ms max_range)a)

    defp cast_and_validate_by_type(changeset, _attrs), do: add_error(changeset, :type, "Invalid type")
  end
end
