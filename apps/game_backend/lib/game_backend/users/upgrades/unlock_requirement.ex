defmodule GameBackend.Users.Upgrades.UnlockRequirement do
  @moduledoc """
  Unlock requirements are used to determine which upgrades are required to unlock a new upgrade.
  """
  use GameBackend.Schema
  import Ecto.Changeset
  alias GameBackend.Users.Upgrade

  schema "upgrade_unlocks" do
    belongs_to(:upgrade_locking, Upgrade)
    belongs_to(:upgrade_unlocked, Upgrade)

    timestamps()
  end

  def changeset(unlock_requirement, attrs \\ %{}) do
    unlock_requirement
    |> cast(attrs, [:upgrade_locking_id, :upgrade_unlocked_id])
  end
end
