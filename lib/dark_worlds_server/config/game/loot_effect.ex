defmodule DarkWorldsServer.Config.Game.LootEffect do
  use Ecto.Schema
  import Ecto.Changeset
  alias DarkWorldsServer.Config.Characters.Effect
  alias DarkWorldsServer.Config.Game.Loot

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "loot_effects" do
    belongs_to(:loot, Loot)
    belongs_to(:effect, Effect)

    timestamps()
  end

  @doc false
  def changeset(loot_effect, attrs) do
    loot_effect
    |> cast(attrs, [:loot_id, :effect_id])
    |> validate_required([:loot_id, :effect_id])
  end
end
