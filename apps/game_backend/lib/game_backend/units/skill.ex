defmodule GameBackend.Units.Skill do
  @moduledoc false

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Units.Skills.Effect

  schema "skills" do
    embeds_many(:effects, Effect)
    field(:cooldown, :integer)
    timestamps()
  end

  @doc false
  def changeset(skill, attrs \\ %{}) do
    skill
    |> cast(attrs, [:cooldown])
    |> cast_embed(:effects)
  end
end
