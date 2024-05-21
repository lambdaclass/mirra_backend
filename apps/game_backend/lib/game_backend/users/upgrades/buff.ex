defmodule GameBackend.Users.Upgrades.Buff do
  @moduledoc """
  Buffs encompass positive and negative effects that can be applied to a unit before battles begin.
  These are typically applied by dungeon upgrades.

  They contain an identifying name, a map of modifiers, and a reference to the skill that applies them.

  The `max_level` field can be altered with the modifiers to cap the level of the unit.
  """

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Users.Upgrade
  alias GameBackend.Units.Skills.Skill

  # For now we can use the same modifiers that we use for skills.
  # If this changes in the future we can just create a new one.
  alias GameBackend.Units.Skills.Mechanics.Effects.Modifier

  schema "buffs" do
    embeds_many(:modifiers, Modifier)

    # Unimplemented until we have passive effects.
    has_many(:skills, Skill)

    belongs_to(:upgrade, Upgrade)

    timestamps()
  end

  def changeset(buff, attrs \\ %{}) do
    buff
    |> cast(attrs, [:upgrade_id, :upgrade_id])
    |> cast_embed(:modifiers)
    |> cast_assoc(:skills)
  end
end
