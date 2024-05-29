defmodule GameBackend.Users.Upgrades.UpgradeDependency do
  @moduledoc """
  UpgradeDependencies are used to determine which upgrades are required for a user in order to unlock a new upgrade.
  """
  use GameBackend.Schema
  import Ecto.Changeset
  alias GameBackend.Users.Upgrade

  schema "upgrade_dependencies" do
    belongs_to(:blocked_upgrade, Upgrade)
    belongs_to(:depends_on, Upgrade)

    timestamps()
  end

  def changeset(upgrade_dependency, attrs \\ %{}) do
    upgrade_dependency
    |> cast(attrs, [:blocked_upgrade_id, :depends_on_id])
  end
end
