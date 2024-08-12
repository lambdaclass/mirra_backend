defmodule GameBackend.Items.ConsumableItem do
  @moduledoc """
  ConsumableItem schema
  """
  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Configuration.Version

  @derive {Jason.Encoder, only: [:name, :radius, :effects, :mechanics, :effect]}
  schema "consumable_items" do
    field(:active, :boolean, default: false)
    field(:name, :string)
    field(:radius, :float)
    field(:effects, {:array, :string})
    field(:mechanics, {:map, :map})

    belongs_to(:version, Version)

    embeds_one(:effect, GameBackend.CurseOfMirra.Effect)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(consumable_item, attrs) do
    consumable_item
    |> cast(attrs, [:name, :radius, :mechanics, :active, :version_id])
    |> validate_required([:name, :radius])
    |> cast_embed(:effect)
  end
end
