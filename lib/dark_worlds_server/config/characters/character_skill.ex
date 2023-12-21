defmodule DarkWorldsServer.Config.Characters.CharacterSkill do
  @moduledoc """
  The Character-Skill association intermediate table.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias DarkWorldsServer.Config.Characters.Character
  alias DarkWorldsServer.Config.Characters.Skill

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "character_skills" do
    belongs_to(:character, Character)
    belongs_to(:skill, Skill)
    field(:skill_number, :integer)

    timestamps()
  end

  @doc false
  def changeset(character_skill, attrs) do
    character_skill
    |> cast(attrs, [:character_id, :skill_id, :skill_number])
    |> validate_required([:character_id, :skill_id, :skill_number])
  end
end
