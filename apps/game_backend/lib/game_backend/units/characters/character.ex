defmodule GameBackend.Units.Characters.Character do
  @moduledoc """
  Characters are the template on which units are based.
  """

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Units.Skill

  schema "characters" do
    field(:game_id, :integer)
    field(:active, :boolean, default: true)
    field(:name, :string)
    field(:title, :string)
    field(:lore, :string)
    field(:faction, :string)
    field(:class, :string)
    field(:quality, :string)

    field(:base_health, :integer)
    field(:base_attack, :integer)
    field(:base_armor, :integer)

    belongs_to(:basic_skill, Skill)
    belongs_to(:ultimate_skill, Skill)

    timestamps()
  end

  @doc false
  def changeset(character, attrs) do
    character
    |> cast(attrs, [
      :game_id,
      :name,
      :active,
      :faction,
      :quality,
      :title,
      :lore,
      :class,
      :basic_skill_id,
      :ultimate_skill_id,
      :base_health,
      :base_attack,
      :base_armor
    ])
    |> cast_assoc(:basic_skill)
    |> cast_assoc(:ultimate_skill)
    |> validate_required([:game_id, :name, :active, :faction])
  end
end
