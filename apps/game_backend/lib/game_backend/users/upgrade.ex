defmodule GameBackend.Users.Upgrade do
  @moduledoc """
  Upgrades can be bought by players for a cost, and in return unlock new features or buffs.
  These are represented by strings in the User schema.
  """
  alias GameBackend.Units.Buffs.Buff
  alias GameBackend.Users.Currencies.CurrencyCost
  alias GameBackend.Users.Upgrade.UnlockRequirement

  use GameBackend.Schema
  import Ecto.Changeset

  schema "upgrades" do
    field(:game_id, :integer)
    field(:name, :string)
    field(:description, :string)
    # Used to group various entries that belong to the same attribute. If Group == -1, accept this entry as a base one.
    field(:group, :integer)

    embeds_many(:cost, CurrencyCost)

    has_many(:unlock_requirements, UnlockRequirement)

    has_many(:unlocks, through: [:unlock_requirements, :upgrade_unlocked])
    has_many(:locked_by, through: [:unlock_requirements, :upgrade_locking])

    has_many(:buffs, Buff)

    timestamps()
  end

  def changeset(upgrade, attrs \\ %{}) do
    upgrade
    |> cast(attrs, [:game_id, :name, :description, :group])
    |> cast_embed(:cost)
    |> validate_required([:game_id, :name])
  end
end

defmodule GameBackend.Users.Upgrade.UnlockRequirement do
  @moduledoc """
  Unlock requirements are used to determine which upgrades are required to unlock a new upgrade.
  """
  use GameBackend.Schema
  import Ecto.Changeset

  schema "upgrade_unlocks" do
    belongs_to(:upgrade_locking, Upgrade)
    belongs_to(:upgrade_unlocked, Upgrade)

    timestamps()
  end

  def changeset(unlock_requirement, attrs \\ %{}) do
    unlock_requirement
    |> cast(attrs, [:upgrade_locking_id, :upgrade_unlocked_id])
    |> validate_required([:upgrade_locking_id, :upgrade_unlocked_id])
  end
end
