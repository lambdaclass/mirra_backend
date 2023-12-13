defmodule DarkWorldsServer.EffectSkill do
  use Ecto.Schema
  import Ecto.Changeset

  alias DarkWorldsServer.Effect
  alias DarkWorldsServer.Skill

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "effect_skills" do
    belongs_to(:effect, Effect)
    belongs_to(:skill, Skill)

    timestamps()
  end

  @doc false
  def changeset(effect_skill, attrs) do
    effect_skill
    |> cast(attrs, [:effect_id, :skill_id])
    |> validate_required([:effect_id, :skill_id])
  end
end
