defmodule GameBackend.Users.Upgrade do
  @moduledoc """
  Upgrades can be bought by players for a cost, and in return unlock new features or buffs.
  These are represented by strings in the User schema.
  """
  alias GameBackend.Users.Currencies.CurrencyCost
  alias GameBackend.Users.Upgrades.{Buff, UpgradeDependency}

  use GameBackend.Schema
  import Ecto.Changeset

  schema "upgrades" do
    field(:game_id, :integer)
    field(:name, :string)
    field(:description, :string)
    # Used to group various entries that belong to the same attribute. If Group == -1, accept this entry as a base one.
    field(:group, :integer)

    embeds_many(:cost, CurrencyCost)

    # These relations are used to determine dependencies between upgrades. Check the UpgradeDependency schema for more information.
    has_many(:upgrade_dependency_blocks, UpgradeDependency, foreign_key: :depends_on_id)
    has_many(:upgrade_dependency_depends_on, UpgradeDependency, foreign_key: :blocked_upgrade_id)

    has_many(:unblocks, through: [:upgrade_dependency_blocks, :blocked_upgrade])
    has_many(:depends_on, through: [:upgrade_dependency_depends_on, :depends_on])

    has_many(:buffs, Buff)

    timestamps()
  end

  def changeset(upgrade, attrs \\ %{}) do
    upgrade
    |> cast(attrs, [:game_id, :name, :description, :group])
    |> cast_embed(:cost)
    |> cast_assoc(:buffs)
    |> cast_assoc(:upgrade_dependency_blocks)
    |> cast_assoc(:upgrade_dependency_depends_on)
    |> validate_required([:game_id, :name])
  end
end
