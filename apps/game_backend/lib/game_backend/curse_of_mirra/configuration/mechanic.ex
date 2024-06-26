defmodule GameBackend.CurseOfMirra.Configuration.Mechanic do
  use GameBackend.Schema
  import Ecto.Changeset

  schema "config_mechanics" do
    field :name, :string
    field :offset, :integer
    field :type, :string
    field :speed, :decimal
    field :range, :decimal
    field :amount, :integer
    field :angle_between, :decimal
    field :damage, :integer
    field :duration_ms, :integer
    field :effects_to_apply, {:array, :string}
    field :interval_ms, :integer
    field :move_by, :decimal
    field :projectile_offset, :integer
    field :radius, :decimal
    field :remove_on_collision, :boolean, default: false

    belongs_to :on_arrival_mechanic, __MODULE__
    belongs_to :on_explode_mechanic, __MODULE__

    timestamps(type: :utc_datetime)
  end

  @types ["circle_hit", "spawn_pool", "leap", "multi_shoot", "dash", "multi_circle_hit", "teleport", "simple_shoot"]

  def types() do
    @types
  end

  @doc false
  def changeset(mechanic, attrs) do
    mechanic
    |> cast(attrs, [:type, :amount, :angle_between, :damage, :duration_ms, :effects_to_apply, :interval_ms, :move_by, :name, :offset, :projectile_offset, :radius, :range, :remove_on_collision, :speed])
    |> validate_required([:type])
    |> validate_inclusion(:type, @types)
  end
end
