defmodule DarkWorldsServer.Config.Characters.Skill do
  @moduledoc """
  Skills are the abilities and attacks a player can cast.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias DarkWorldsServer.Config.Characters.SkillMechanic

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "skills" do
    field(:name, :string)
    field(:cooldown_ms, :integer)
    field(:execution_duration_ms, :integer)
    field(:is_passive, :boolean)
    field(:mechanics, {:array, SkillMechanic})
    field(:burst_loads, :integer)
    timestamps()
  end

  @doc false
  def changeset(skill, attrs),
    do:
      skill
      |> cast(attrs, [:name, :cooldown_ms, :execution_duration_ms, :is_passive, :mechanics, :burst_loads])
      |> validate_required([:name, :cooldown_ms, :execution_duration_ms, :is_passive, :mechanics, :burst_loads])

  def to_backend_map(skill),
    do: %{
      name: skill.name,
      cooldown_ms: skill.cooldown_ms,
      execution_duration_ms: skill.execution_duration_ms,
      is_passive: skill.is_passive,
      burst_loads: skill.burst_loads,
      mechanics: Enum.map(skill.mechanics, &SkillMechanic.to_backend_map/1)
    }
end
