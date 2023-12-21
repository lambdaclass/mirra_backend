defmodule DarkWorldsServer.Config.Characters.ProjectileEffect do
  @moduledoc """
  The Projectile-Effect association intermediate table.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias DarkWorldsServer.Config.Characters.Effect
  alias DarkWorldsServer.Config.Characters.Projectile

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "projectile_effects" do
    belongs_to(:projectile, Projectile)
    belongs_to(:effect, Effect)

    timestamps()
  end

  @doc false
  def changeset(projectile_effect, attrs) do
    projectile_effect
    |> cast(attrs, [:projectile_id, :effect_id])
    |> validate_required([:projectile_id, :effect_id])
  end
end
