defmodule GameBackend.Units.Skill do
  @moduledoc false

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Units.Skills.Effect

  schema "skills" do
    field(:name, :string)
    embeds_many(:effects, Effect)
    field(:cooldown, :integer)
    field(:energy_regen, :integer)
    field(:delay, :integer)
    timestamps()
  end

  @doc false
  def changeset(skill, attrs \\ %{}) do
    skill
    |> cast(attrs, [:name, :cooldown, :energy_regen, :delay])
    |> cast_embed(:effects)
  end
end
