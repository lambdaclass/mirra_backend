defmodule DarkWorldsServer.Characters.Skill do
  use Ecto.Schema
  import Ecto.Changeset

  alias DarkWorldsServer.Characters.SkillMechanic

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "skills" do
    field(:name, :string)
    field(:cooldown_ms, :integer)
    field(:execution_duration_ms, :integer)
    field(:is_passive, :boolean)

    field(:mechanics, {:array, SkillMechanic})

    timestamps()
  end

  @doc false
  def changeset(skill, attrs),
    do:
      skill
      |> cast(attrs, [:name, :cooldown_ms, :execution_duration_ms, :is_passive])
      |> cast_mechanics(attrs[:mechanics])
      |> validate_required([:name, :cooldown_ms, :execution_duration_ms, :is_passive, :mechanics])

  defp cast_mechanics(changeset, value) do
    cast(changeset, %{mechanics: value}, [:mechanics])
  end
end
