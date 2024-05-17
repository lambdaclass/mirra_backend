defmodule GameBackend.Users.Upgrade do
  @moduledoc """
  Upgrades can be bought by players for a cost, and in return unlock new features or buffs.
  These are represented by strings in the User schema.
  """
  alias GameBackend.Units.Buffs.Buff
  alias GameBackend.Users.Currencies.CurrencyCost
  alias GameBackend.Users.Upgrades.UnlockRequirement

  use GameBackend.Schema
  import Ecto.Changeset

  schema "upgrades" do
    field(:game_id, :integer)
    field(:name, :string)
    field(:description, :string)
    # Used to group various entries that belong to the same attribute. If Group == -1, accept this entry as a base one.
    field(:group, :integer)

    embeds_many(:cost, CurrencyCost)

    has_many(:unlock_requirement_unlocks, UnlockRequirement, foreign_key: :upgrade_unlocked_id)
    has_many(:unlock_requirement_locked_by, UnlockRequirement, foreign_key: :upgrade_unlocked_id)

    has_many(:unlocks, through: [:unlock_requirement_unlocks, :upgrade_unlocked])
    has_many(:locked_by, through: [:unlock_requirement_locked_by, :upgrade_locking])

    has_many(:buffs, Buff)

    timestamps()
  end

  def changeset(upgrade, attrs \\ %{}) do
    upgrade
    |> cast(attrs, [:game_id, :name, :description, :group])
    |> cast_embed(:cost)
    |> cast_assoc(:unlock_requirement_unlocks)
    |> cast_assoc(:unlock_requirement_locked_by)
    |> validate_required([:game_id, :name])
  end
end
