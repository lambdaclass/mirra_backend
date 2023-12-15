defmodule DarkWorldsServer.Config.Games.ZoneModificationEffect do
  use Ecto.Schema
  import Ecto.Changeset
  alias DarkWorldsServer.Config.Characters.Effect
  alias DarkWorldsServer.Config.Games.ZoneModification

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "zone_effects" do
    belongs_to(:zone_modification, ZoneModification)
    belongs_to(:effect, Effect)

    timestamps()
  end

  @doc false
  def changeset(zone_effect, attrs) do
    zone_effect
    |> cast(attrs, [:zone_modification_id, :effect_id])
    |> validate_required([:zone_modification_id, :effect_id])
  end
end
