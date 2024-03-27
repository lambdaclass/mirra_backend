defmodule GameBackend.Units.Skill do
  @moduledoc false

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Units.Skills.Effect

  schema "skills" do
    field(:name, :string)
    embeds_many(:effects, Effect, on_replace: :delete)
    field(:cooldown, :integer)
    field(:energy_regen, :integer)
    field(:animation_duration, :integer)
    field(:animation_trigger, :integer)

    timestamps()
  end

  @doc false
  def changeset(skill, attrs \\ %{}) do
    skill
    |> cast(attrs, [:name, :cooldown, :energy_regen, :animation_duration, :animation_trigger])
    |> cast_embed(:effects)
  end
end
