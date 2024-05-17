defmodule GameBackend.Units.Skills.Skill do
  @moduledoc false

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Units.Buffs.Buff
  alias GameBackend.Units.Skills.Mechanic

  schema "skills" do
    field(:name, :string)
    has_many(:mechanics, Mechanic, on_replace: :delete)
    field(:cooldown, :integer)
    field(:energy_regen, :integer)
    field(:animation_duration, :integer)

    belongs_to(:buff, Buff)

    timestamps()
  end

  @doc false
  def changeset(skill, attrs \\ %{}) do
    skill
    |> cast(attrs, [:name, :cooldown, :energy_regen, :animation_duration, :buff_id])
    |> cast_assoc(:mechanics)
  end
end
