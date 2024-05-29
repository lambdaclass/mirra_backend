defmodule GameBackend.Users.Unlock do
  @moduledoc """
  Things that have been unlocked by Users.

  Unlocks can be plain strings like "fusion_feature" or "summon_feature", or they can be references to upgrades.
  """
  alias GameBackend.Users.{Upgrade, User}

  use GameBackend.Schema
  import Ecto.Changeset

  schema "unlocks" do
    belongs_to(:user, User)

    field(:name, :string)
    belongs_to(:upgrade, Upgrade)

    field(:type, :string)

    timestamps()
  end

  @doc false
  def changeset(unlock, attrs) do
    unlock |> cast(attrs, [:user_id, :name, :upgrade_id, :type]) |> cast_assoc(:upgrade)
  end
end
