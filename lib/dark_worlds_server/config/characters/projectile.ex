defmodule DarkWorldsServer.Config.Characters.Projectile do
  use Ecto.Schema
  import Ecto.Changeset
  alias DarkWorldsServer.Config.Characters.Effect
  alias DarkWorldsServer.Config.Characters.ProjectileEffect

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "projectiles" do
    field(:name, :string)
    field(:base_damage, :integer)
    field(:base_speed, :integer)
    field(:base_size, :integer)
    field(:duration_ms, :integer)
    field(:max_distance, :integer)
    field(:remove_on_collision, :boolean)

    many_to_many(:on_hit_effects, Effect, join_through: ProjectileEffect)
    timestamps()
  end

  @doc false
  def changeset(skill, attrs),
    do:
      skill
      |> cast(attrs, [:name, :base_damage, :base_speed, :base_size, :duration_ms, :max_distance, :remove_on_collision])
      |> validate_required([
        :name,
        :base_damage,
        :base_speed,
        :base_size,
        :duration_ms,
        :max_distance,
        :remove_on_collision
      ])
end
