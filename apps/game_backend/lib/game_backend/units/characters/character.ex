defmodule GameBackend.Units.Characters.Character do
  @moduledoc """
  Characters are the template on which units are based.
  """

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Units.Skill

  @derive {Jason.Encoder, only: [:active, :name, :faction, :rarity]}
  schema "characters" do
    field(:game_id, :integer)
    field(:active, :boolean, default: true)
    field(:name, :string)
    field(:class, :string)
    field(:faction, :string)
    field(:rarity, :integer)
    field(:ranks_dropped_in, {:array, :integer})

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
      :rarity,
      :ranks_dropped_in,
      :basic_skill_id,
      :ultimate_skill_id,
      :base_health,
      :base_attack,
      :base_armor
    ])
    |> cast_assoc(:basic_skill)
    |> cast_assoc(:ultimate_skill)
    |> validate_required([:game_id, :name, :active, :class, :faction])
  end
end
