defmodule DarkWorldsServer.Config.Characters.Character do
  @moduledoc """
  Characters are the template on which players are based.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias DarkWorldsServer.Config.Characters
  alias DarkWorldsServer.Config.Characters.CharacterSkill
  alias DarkWorldsServer.Config.Characters.Skill

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "characters" do
    field(:active, :boolean, default: false)
    field(:name, :string)
    field(:base_speed, :integer)
    field(:base_size, :integer)
    field(:base_health, :integer)
    field(:max_inventory_size, :integer)

    many_to_many(:skills, Skill, join_through: CharacterSkill)

    timestamps()
  end

  @doc false
  def changeset(character, attrs) do
    character
    |> cast(attrs, [:name, :active, :base_speed, :base_size, :base_health, :max_inventory_size])
    |> validate_required([:name, :active, :base_speed, :base_size, :base_health, :max_inventory_size])
  end

  def to_backend_map(character),
    do: %{
      active: character.active,
      name: character.name,
      base_speed: character.base_speed,
      base_size: character.base_size,
      base_health: character.base_health,
      max_inventory_size: character.max_inventory_size,
      skills:
        Enum.into(character.skills, %{}, fn skill ->
          {Integer.to_string(Characters.get_character_skill_number(character.id, skill.id)),
           Skill.to_backend_map(skill)}
        end)
    }
end
